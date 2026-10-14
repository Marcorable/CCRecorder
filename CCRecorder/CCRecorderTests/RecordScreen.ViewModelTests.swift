
import Testing

@testable import CCRecorder

@Suite("녹음 화면 ViewModel")
@MainActor
struct RecordScreenViewModelTests {
    private let recorder = MockAudioRecording(
        currentTime: .zero,
        pins: []
    )
    private let viewModel: RecordScreen.ViewModel

    init() {
        viewModel = .init(model: .init(dependency: .init(recorder: recorder)))
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

}

private extension RecordScreenViewModelTests {

    func waitForAlert() async {
        for _ in 0..<20 where viewModel.alert == nil {
            await Task.yield()
        }
    }

}
