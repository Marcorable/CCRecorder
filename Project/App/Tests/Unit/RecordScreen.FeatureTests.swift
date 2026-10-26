
import Foundation
import SwiftData
import Testing

import ComposableArchitecture

@testable import CCRecorder

@Suite("녹음 화면 Feature")
@MainActor
struct RecordScreenFeatureTests {
    private let clock = TestClock()
    private let recordUsecaseSpy = RecordUsecaseSpy()
    private let saveConversationUsecaseSpy = SaveConversationUsecaseSpy()

    init() {
        uncheckedUseMainSerialExecutor = true
    }
}

extension RecordScreenFeatureTests {

    @Test("녹음 준비가 끝나면 대기 상태가 된다")
    func prepareSuccess() async {
        // given
        let store = makeStore()

        // when
        await store.send(.view(.task))

        // then
        await store.receive(\.response.prepare) {
            $0.phase = .idle
        }
    }

    @Test("마이크 권한이 없으면 설정 안내를 표시한다")
    func preparePermissionDenied() async {
        // given
        recordUsecaseSpy.prepareResult = .failure(.permissionDenied)
        let store = makeStore()

        // when
        await store.send(.view(.task))

        // then
        await store.receive(\.response.prepare) {
            $0.phase = .idle
            $0.alert = .permissionDenied
        }
    }

    @Test("녹음 버튼은 녹음과 일시정지 상태를 오간다")
    func toggleRecording() async {
        // given
        recordUsecaseSpy.startState = .recording
        recordUsecaseSpy.pauseState = .paused
        let store = makeStore(phase: .idle)

        // when
        await store.send(.view(.toggleRecordingButtonTapped))

        // then
        await store.receive(\.response.recorderUpdated) {
            $0.phase = .recording
            $0.currentTime = 3
        }

        // when
        await store.send(.view(.toggleRecordingButtonTapped))

        // then
        await store.receive(\.response.recorderUpdated) {
            $0.phase = .paused
        }
        #expect(recordUsecaseSpy.startCallCount == 1)
        #expect(recordUsecaseSpy.pauseCallCount == 1)
    }

    @Test("녹음 중 핀을 추가하면 현재 시간이 상태에 저장된다")
    func addPin() async {
        // given
        let store = makeStore(
            phase: .recording,
            currentTime: 3
        )

        // when, then
        await store.send(.view(.addPinButtonTapped)) {
            $0.pins = [3]
        }
    }

    @Test("핀을 삭제하면 상태에서 제거된다")
    func removePin() async {
        // given
        let store = makeStore(
            phase: .paused,
            currentTime: 7.5,
            pins: [2, 7.5]
        )

        // when, then
        await store.send(.view(.removePinButtonTapped(0))) {
            $0.pins = [7.5]
        }
    }

    @Test("녹음 시간이 없으면 저장 확인을 표시하지 않는다")
    func requestSaveWithoutRecording() async {
        // given
        let store = makeStore(phase: .idle)

        // when
        await store.send(.view(.requestSaveButtonTapped))

        // then
        #expect(store.state.alert == nil)
    }

    @Test("취소를 확정하면 녹음물을 지우고 화면 종료 상태가 된다")
    func confirmCancel() async {
        // given
        let store = makeStore(phase: .paused)
        await store.send(.view(.requestCancelButtonTapped)) {
            $0.alert = .confirmCancel
        }

        // when
        await store.send(.alert(.presented(.cancelConfirmed))) {
            $0.alert = nil
            $0.isFinished = true
        }

        // then
        await store.finish()
        #expect(recordUsecaseSpy.cancelCallCount == 1)
    }

    @Test("저장을 확정하면 화면 정보와 핀을 저장 Usecase에 전달한다")
    func confirmSave() async {
        // given
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let store = makeStore(
            phase: .paused,
            currentTime: 3,
            pins: [1, 3],
            date: date
        )
        await store.send(.conversationInfo(.binding(.set(\.title, "카페 대화")))) {
            $0.conversationInfo.title = "카페 대화"
        }
        await store.send(.conversationInfo(.binding(.set(\.topic, "여행")))) {
            $0.conversationInfo.topic = "여행"
        }
        await store.send(.conversationInfo(.binding(.set(\.parties, ["Tom", "Jane"])))) {
            $0.conversationInfo.parties = ["Tom", "Jane"]
        }
        await store.send(.view(.requestSaveButtonTapped)) {
            $0.alert = .confirmSave
        }

        // when
        await store.send(.alert(.presented(.saveConfirmed))) {
            $0.alert = nil
            $0.phase = .saving
        }

        // then
        await store.receive(\.response.save) {
            $0.isFinished = true
        }
        await store.finish()
        #expect(
            saveConversationUsecaseSpy.input == .init(
                fileURL: recordUsecaseSpy.finishURL,
                createdDate: date,
                title: "카페 대화",
                topic: "여행",
                parties: ["Tom", "Jane"],
                pins: [1, 3]
            )
        )
    }

    @Test(
        "제목이 비어 있으면 저장 날짜를 제목으로 전달한다",
        arguments: ["", "   "]
    )
    func confirmSaveWithEmptyTitle(title: String) async {
        // given
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let store = makeStore(
            phase: .paused,
            currentTime: 3,
            date: date
        )
        await store.send(.conversationInfo(.binding(.set(\.title, title)))) {
            $0.conversationInfo.title = title
        }
        await store.send(.view(.requestSaveButtonTapped)) {
            $0.alert = .confirmSave
        }

        // when
        await store.send(.alert(.presented(.saveConfirmed))) {
            $0.alert = nil
            $0.phase = .saving
        }

        // then
        await store.receive(\.response.save) {
            $0.isFinished = true
        }
        await store.finish()
        #expect(
            saveConversationUsecaseSpy.input?.title == date.formatted(
                date: .abbreviated,
                time: .omitted
            )
        )
    }

    @Test("저장에 실패하면 실패 안내를 표시한다")
    func saveFailure() async {
        // given
        saveConversationUsecaseSpy.failure = .saveFailed
        let store = makeStore(
            phase: .paused,
            currentTime: 3
        )
        await store.send(.view(.requestSaveButtonTapped)) {
            $0.alert = .confirmSave
        }

        // when
        await store.send(.alert(.presented(.saveConfirmed))) {
            $0.alert = nil
            $0.phase = .saving
        }

        // then
        await store.receive(\.response.save) {
            $0.phase = .idle
            $0.alert = .saveFailed
        }
    }

    @Test("저장하지 않고 화면을 벗어나면 녹음물을 지운다")
    func disappearWithoutFinishing() async {
        // given
        let store = makeStore(phase: .paused)

        // when
        await store.send(.view(.disappeared)) {
            $0.isFinished = true
        }

        // then
        await store.finish()
        #expect(recordUsecaseSpy.cancelCallCount == 1)
    }

    @Test("준비 중 화면을 벗어나면 늦은 준비 응답을 무시하고 녹음물을 지운다")
    func disappearWhilePreparing() async {
        // given
        recordUsecaseSpy.isPrepareSuspended = true
        let store = makeStore()
        await store.send(.view(.task))
        await waitUntilPrepareIsSuspended()

        // when
        await store.send(.view(.disappeared)) {
            $0.isFinished = true
        }
        recordUsecaseSpy.resumePrepare()

        // then
        await store.finish()
        await store.send(.response(.prepare(.success(.recording))))
        #expect(store.state.phase == .preparing)
        #expect(recordUsecaseSpy.cancelCallCount == 1)
    }

    @Test("준비 중 취소를 확정하면 늦은 준비 응답을 무시하고 녹음물을 지운다")
    func confirmCancelWhilePreparing() async {
        // given
        recordUsecaseSpy.isPrepareSuspended = true
        let store = makeStore()
        await store.send(.view(.task))
        await waitUntilPrepareIsSuspended()
        await store.send(.view(.requestCancelButtonTapped)) {
            $0.alert = .confirmCancel
        }

        // when
        await store.send(.alert(.presented(.cancelConfirmed))) {
            $0.alert = nil
            $0.isFinished = true
        }
        recordUsecaseSpy.resumePrepare()

        // then
        await store.finish()
        #expect(store.state.phase == .preparing)
        #expect(recordUsecaseSpy.cancelCallCount == 1)
    }

}

private extension RecordScreenFeatureTests {

    func makeStore(
        phase: RecordScreen.Root.Feature.State.Phase = .preparing,
        currentTime: TimeInterval = .zero,
        pins: [TimeInterval] = [],
        date: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> TestStoreOf<RecordScreen.Root.Feature> {
        var state = RecordScreen.Root.Feature.State()
        state.phase = phase
        state.currentTime = currentTime
        state.pins = pins

        return .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.continuousClock = clock
                $0.date.now = date
                $0.recordUsecase = recordUsecaseSpy.usecase
                $0.saveConversationUsecase = saveConversationUsecaseSpy.usecase
            }
        )
    }

    func waitUntilPrepareIsSuspended() async {
        while !recordUsecaseSpy.isPrepareWaiting {
            await Task.yield()
        }
    }

}

@Suite("RecordUsecase")
@MainActor
struct RecordUsecaseTests {

    @Test("녹음 상태는 RecorderService 상태와 시간을 반환한다")
    func stateReturnsServiceState() async {
        // given
        let service = MockRecorderService(
            isRecording: true,
            currentTime: 3
        )
        let usecase = RecordUsecase.live(service: service)

        // when
        let state = await usecase.state()

        // then
        #expect(state == .recording)
    }

    @Test("녹음을 끝내지 못하면 finishFailed를 던진다")
    func finishFailure() async {
        // given
        let service = MockRecorderService()
        service.error = RecorderServiceFailure.notPrepared
        let usecase = RecordUsecase.live(service: service)

        // when, then
        await #expect {
            try await usecase.finish()
        } throws: { error in
            error as? RecordUsecase.Failure == .finishFailed
        }
    }

}

@Suite("SaveConversationUsecase")
@MainActor
struct SaveConversationUsecaseTests {

    @Test("대화 정보와 핀을 Conversation으로 저장한다")
    func executeSavesConversation() async throws {
        // given
        let repository = MockConversationRepository()
        let usecase = SaveConversationUsecase.live(
            repository: repository,
            fileStore: .init()
        )
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        // when
        try await usecase.execute(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/mock.m4a"),
                createdDate: date,
                title: "카페 대화",
                topic: "여행",
                parties: ["Tom", "Jane"],
                pins: [2, 7.5]
            )
        )

        // then
        let conversation = try #require(repository.conversations.first)
        #expect(conversation.title == "카페 대화")
        #expect(conversation.topic == "여행")
        #expect(Set(conversation.parties.map(\.name)) == ["Tom", "Jane"])
        #expect(conversation.pins == [2, 7.5])
        #expect(conversation.createdDate == date)
    }

    @Test("저장에 실패하면 완성된 녹음 파일을 삭제한다")
    func executeFailureRemovesFile() async throws {
        // given
        let repository = MockConversationRepository()
        repository.error = TestFailure.save
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try Data().write(to: fileURL)
        let fileStore = RecordFileStore()
        let usecase = SaveConversationUsecase.live(
            repository: repository,
            fileStore: fileStore
        )

        // when
        do {
            try await usecase.execute(
                .init(
                    fileURL: fileURL,
                    createdDate: .now,
                    title: "카페 대화",
                    topic: "",
                    parties: [],
                    pins: []
                )
            )
            Issue.record("저장이 실패해야 한다")
        } catch {
            #expect(error as? SaveConversationUsecase.Failure == .saveFailed)
        }

        // then
        #expect(!fileStore.fileExists(at: fileURL))
    }

}

@MainActor
private final class RecordUsecaseSpy: @unchecked Sendable {
    var prepareResult: Result<RecordUsecase.State, RecordUsecase.Failure> = .success(.idle)
    var isPrepareSuspended: Bool = false
    private(set) var isPrepareWaiting: Bool = false
    var startState: RecordUsecase.State = .idle
    var pauseState: RecordUsecase.State = .idle
    var currentState: RecordUsecase.State = .idle
    var finishURL = URL(fileURLWithPath: "/tmp/mock.m4a")
    var startCallCount: Int = .zero
    var pauseCallCount: Int = .zero
    var cancelCallCount: Int = .zero
    private var prepareContinuation: CheckedContinuation<Void, Never>?

    var usecase: RecordUsecase {
        .init(
            prepare: { [self] in
                if isPrepareSuspended {
                    isPrepareWaiting = true
                    await withCheckedContinuation { continuation in
                        prepareContinuation = continuation
                    }
                    isPrepareWaiting = false
                }
                return try prepareResult.get()
            },
            start: { [self] in
                startCallCount += 1
                return startState
            },
            pause: { [self] in
                pauseCallCount += 1
                return pauseState
            },
            state: { [self] in currentState },
            finish: { [self] in finishURL },
            cancel: { [self] in cancelCallCount += 1 }
        )
    }

    func resumePrepare() {
        prepareContinuation?.resume()
        prepareContinuation = nil
    }
}

@MainActor
private final class SaveConversationUsecaseSpy: @unchecked Sendable {
    var input: SaveConversationUsecase.Input?
    var failure: SaveConversationUsecase.Failure?

    var usecase: SaveConversationUsecase {
        .init(
            execute: { [self] input in
                if let failure {
                    throw failure
                }
                self.input = input
            }
        )
    }
}

private extension RecordUsecase.State {

    static var recording: Self {
        .init(
            isRecording: true,
            currentTime: 3
        )
    }

    static var paused: Self {
        .init(
            isRecording: false,
            currentTime: 3
        )
    }

}

private enum TestFailure: Error {
    case save
}
