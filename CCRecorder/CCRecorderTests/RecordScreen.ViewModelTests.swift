
import Foundation
import SwiftData
import Testing

@testable import CCRecorder

@Suite("녹음 화면 ViewModel")
@MainActor
struct RecordScreenViewModelTests {
    private let recorder = MockAudioRecording(
        currentTime: .zero,
        pins: []
    )
    private let modelContext: ModelContext = .mock
    private let viewModel: RecordScreen.ViewModel

    init() {
        viewModel = .init(
            model: .init(
                dependency: .init(
                    recorder: recorder,
                    modelContext: modelContext,
                    fileStore: .init()
                )
            )
        )
    }
}

extension RecordScreenViewModelTests {

    @Test("마이크 권한이 없으면 권한 안내 알럿을 띄운다")
    func prepare_permissionDenied() async {
        recorder.error = AudioRecorder.RecordError.permissionDenied

        viewModel.reduce(by: .prepare)
        await waitForAlert()

        #expect(viewModel.alert == .permissionDenied)
    }

    @Test("준비가 끝나면 알럿을 띄우지 않는다")
    func prepare_success() async {
        viewModel.reduce(by: .prepare)
        await waitForAlert()

        #expect(viewModel.alert == nil)
    }

    @Test("녹음 버튼은 녹음과 일시정지를 오간다")
    func toggleRecording() {
        viewModel.reduce(by: .toggleRecording)
        #expect(viewModel.isRecording)

        viewModel.reduce(by: .toggleRecording)
        #expect(!viewModel.isRecording)
    }

    @Test("녹음 중 핀을 추가하면 화면 표시용 목록에 반영된다")
    func addPinUpdatesPins() {
        // given
        recorder.isRecording = true
        recorder.currentTime = 3.0

        // when
        viewModel.reduce(by: .addPin)

        // then
        #expect(viewModel.pins == [3.0])
    }

    @Test("핀을 삭제하면 화면 표시용 목록에서 제거된다")
    func removePinUpdatesPins() {
        // given
        recorder.pins = [2.0, 7.5]

        // when
        viewModel.reduce(by: .removePin(0))

        // then
        #expect(viewModel.pins == [7.5])
    }

    @Test("녹음한 시간이 없으면 저장 확인을 띄우지 않는다")
    func requestSave_withoutRecording() {
        viewModel.reduce(by: .requestSave)

        #expect(viewModel.alert == nil)
    }

    @Test("녹음한 시간이 있으면 저장 확인을 띄운다")
    func requestSave_afterRecording() {
        recorder.currentTime = 3.0

        viewModel.reduce(by: .requestSave)

        #expect(viewModel.alert == .confirmSave)
    }

    @Test("취소하면 녹음물을 지우고 화면을 닫는다")
    func cancel() {
        viewModel.reduce(by: .requestCancel)
        #expect(viewModel.alert == .confirmCancel)

        viewModel.reduce(by: .cancel)

        #expect(recorder.isCanceled)
        #expect(viewModel.alert == nil)
        #expect(viewModel.isFinished)
    }

    @Test("저장하면 입력한 정보와 핀으로 대화를 만들고 화면을 닫는다")
    func save() throws {
        // given
        recorder.currentTime = 10.0
        recorder.pins = [2.0, 7.5]

        // when
        viewModel.reduce(
            by: .save(
                .init(
                    title: "카페 대화",
                    topic: "여행",
                    parties: ["Tom", "Jane"]
                )
            )
        )

        // then
        let conversation = try #require(fetchConversations().first)
        #expect(conversation.title == "카페 대화")
        #expect(conversation.topic == "여행")
        #expect(Set(conversation.parties.map(\.name)) == ["Tom", "Jane"])
        #expect(conversation.pins == [2.0, 7.5])
        #expect(viewModel.alert == nil)
        #expect(viewModel.isFinished)
    }

    @Test(
        "제목이 비어 있으면 녹음 날짜를 제목으로 쓴다",
        arguments: ["", "  "]
    )
    func saveWithEmptyTitleUsesDate(title: String) throws {
        // when
        viewModel.reduce(
            by: .save(
                .init(
                    title: title,
                    topic: "",
                    parties: []
                )
            )
        )

        // then
        let conversation = try #require(fetchConversations().first)
        #expect(conversation.title == RecordScreen.defaultTitle(of: conversation.createdDate))
    }

    @Test("녹음을 끝내지 못하면 대화를 만들지 않고 실패 알럿을 띄운다")
    func saveFailsWhenFinishFails() throws {
        // given
        recorder.error = AudioRecorder.RecordError.notPrepared

        // when
        viewModel.reduce(
            by: .save(
                .init(
                    title: "카페 대화",
                    topic: "",
                    parties: []
                )
            )
        )

        // then
        #expect(try fetchConversations().isEmpty)
        #expect(viewModel.alert == .saveFailed)
        #expect(!viewModel.isFinished)
    }

}

private extension RecordScreenViewModelTests {

    func fetchConversations() throws -> [Conversation] {
        try modelContext.fetch(FetchDescriptor<Conversation>())
    }

    func waitForAlert() async {
        for _ in 0..<20 where viewModel.alert == nil {
            await Task.yield()
        }
    }

}
