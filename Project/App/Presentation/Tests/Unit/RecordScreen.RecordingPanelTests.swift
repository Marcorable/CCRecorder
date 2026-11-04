
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("녹음 화면 RecordingPanel Feature")
@MainActor
struct RecordScreenRecordingPanelTests {}

extension RecordScreenRecordingPanelTests {

    @Test("녹음 중 현재 초에 따라 녹음 표시를 깜빡인다")
    func recordingIndicatorBlinksWithCurrentTime() {
        var state: RecordScreen.RecordingPanel.Feature.State = .init()
        #expect(state.isRecordingIndicatorVisible)

        state.phase = .recording
        state.currentTime = 2
        #expect(state.isRecordingIndicatorVisible)

        state.currentTime = 3
        #expect(!state.isRecordingIndicatorVisible)
    }

    @Test("녹음 단계에 따라 로딩과 버튼 활성 상태를 계산한다")
    func phaseDerivesLoadingAndButtonAvailability() {
        var state: RecordScreen.RecordingPanel.Feature.State = .init(
            phase: .idle
        )
        #expect(!state.isLoading)
        #expect(state.isAbleToToggleRecording)
        #expect(!state.isAbleToSave)

        state.currentTime = 1
        #expect(state.isAbleToSave)

        state.phase = .preparing
        #expect(state.isLoading)
        #expect(!state.isAbleToToggleRecording)
        #expect(!state.isAbleToSave)

        state.phase = .saving
        #expect(state.isLoading)
        #expect(!state.isAbleToToggleRecording)
        #expect(!state.isAbleToSave)
    }

    @Test("마이크 권한이 없으면 부모 화면에 진입 실패를 알린다")
    func deniedPermissionDelegatesUnavailableAuthorization() async {
        // given
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.RecordingPanel.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .denied }
            }
        )

        // when, then
        await store.send(.parent(.screenAppeared))
        await store.receive(\.response.recordingPreparing) {
            $0.phase = .finished
        }
        await store.receive(\.delegate.authorizationUnavailable)
    }

    @Test("녹음 준비에 성공하면 대기 상태가 된다")
    func preparationMovesToIdle() async {
        // given
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.RecordingPanel.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .authorized }
                $0.audioSession.activate = {}
                $0.recordingUsecase.prepare = {}
                $0.recordingUsecase.currentTime = { 1 }
            }
        )

        // when, then
        await store.send(.parent(.screenAppeared))
        await store.receive(\.response.recordingPreparing)
        await store.receive(\.response.recordingPrepared) {
            $0.phase = .idle
            $0.currentTime = 1
        }
    }

    @Test("녹음 준비에 실패하면 부모 화면에 오류를 알린다")
    func preparationFailureDelegatesError() async {
        // given
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.RecordingPanel.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .authorized }
                $0.audioSession.activate = {}
                $0.recordingUsecase.prepare = {
                    throw DomainError.recordingUsecase(.prepareFailed)
                }
            }
        )

        // when, then
        await store.send(.parent(.screenAppeared))
        await store.receive(\.response.recordingPreparing)
        await store.receive(\.response.recordingFailed) {
            $0.phase = .idle
        }
        await store.receive(\.delegate.recordingFailed)
    }

    @Test("화면이 닫힌 뒤 도착한 준비 응답은 상태를 되살리지 않는다")
    func latePreparationResponseIsIgnored() async {
        // given
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(phase: .finished),
            reducer: { RecordScreen.RecordingPanel.Feature() }
        )

        // when, then
        await store.send(.response(.recordingPrepared(3)))
    }

    @Test("화면이 닫힌 뒤 도착한 ticker 응답은 상태를 되살리지 않는다")
    func lateTickerResponseIsIgnored() async {
        // given
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(
                phase: .finished,
                currentTime: 2
            ),
            reducer: { RecordScreen.RecordingPanel.Feature() }
        )

        // when, then
        await store.send(
            .response(
                .recorderUpdated(
                    isRecording: true,
                    currentTime: 3
                )
            )
        )
    }

    @Test("녹음 저장에 실패하면 부모 화면에 오류를 알린다")
    func saveFailureDelegatesError() async {
        // given
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(phase: .saving),
            reducer: { RecordScreen.RecordingPanel.Feature() }
        )

        // when, then
        await store.send(.response(.recordingFailed(.saveFailed))) {
            $0.phase = .idle
        }
        await store.receive(\.delegate.recordingFailed)
    }

    @Test("녹음 취소를 확정하면 녹음물을 폐기한다")
    func confirmedCancellationDiscardsRecording() async {
        // given
        let cancellation = RecordingPanelCallSpy()
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(
                phase: .recording,
                currentTime: 3
            ),
            reducer: { RecordScreen.RecordingPanel.Feature() },
            withDependencies: {
                $0.recordingUsecase.cancel = {
                    await cancellation.call()
                }
            }
        )

        // when, then
        await store.send(.parent(.discardConfirmed)) {
            $0.phase = .finished
        }
        await store.receive(\.response.recordingDiscarding)
        await store.receive(\.delegate.recordingDiscarded)
        await store.finish()
        #expect(await cancellation.callCount == 1)
    }

    @Test("녹음 저장을 확정하면 대화를 저장한다")
    func confirmedSavePersistsConversation() async {
        // given
        let persistence = RecordingPanelConversationSpy()
        let conversation: Conversation = .init(
            createdDate: .init(timeIntervalSince1970: 0),
            pins: [1],
            title: "English Conversation",
            topic: "Travel",
            parties: [.init(name: "Marco")]
        )
        let store: TestStoreOf<RecordScreen.RecordingPanel.Feature> = .init(
            initialState: .init(
                phase: .paused,
                currentTime: 3,
                pins: [1]
            ),
            reducer: { RecordScreen.RecordingPanel.Feature() },
            withDependencies: {
                $0.recordingUsecase.finish = {
                    await persistence.save($0)
                }
            }
        )

        // when, then
        await store.send(.parent(.saveConfirmed(conversation))) {
            $0.phase = .saving
        }
        await store.receive(\.response.recordingSaving)
        await store.receive(\.response.recordingSaved) {
            $0.phase = .finished
        }
        await store.receive(\.delegate.recordingSaved)
        await store.finish()
        #expect(await persistence.conversation == conversation)
    }

}

private actor RecordingPanelCallSpy {
    private(set) var callCount = 0

    func call() {
        callCount += 1
    }
}

private actor RecordingPanelConversationSpy {
    private(set) var conversation: Conversation?

    func save(_ conversation: Conversation) {
        self.conversation = conversation
    }
}
