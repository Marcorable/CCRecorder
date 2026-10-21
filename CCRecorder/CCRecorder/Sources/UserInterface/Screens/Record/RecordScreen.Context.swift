
import SwiftUI

extension RecordScreen {

    struct Context: View {
        @Environment(\.dismiss) private var dismiss

        @State private var viewModel: ViewModel

        @State private var title: String = RecordScreen.defaultTitle(of: .now)
        @State private var topic: String = ""
        @State private var parties: [Party] = []

        init(viewModel: ViewModel) {
            self._viewModel = .init(initialValue: viewModel)
        }

        var body: some View {
            NavigationView {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        PinGrid(
                            pins: viewModel.pins,
                            isRecording: viewModel.isRecording,
                            currentTime: viewModel.currentTime,
                            delete: { viewModel.reduce(by: .removePin($0)) }
                        )
                        ConversationInfoBox(
                            title: $title,
                            topic: $topic,
                            parties: $parties
                        )
                    }
                    .background(Color.Surface.Recorder.prominent)
                    .clipShape(.rect(cornerRadius: 25))
                    .padding()
                    RecordingPanel(viewModel: viewModel)
                }
                .padding()
                .background(Color.Surface.Recorder.muted)
                .navigationTitle("녹음하기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(
                            action: { viewModel.reduce(by: .requestCancel) },
                            label: {
                                Text("취소")
                                    .font(.headline)
                            }
                        )
                    }
                }
            }
            .task {
                viewModel.reduce(by: .prepare)
            }
            .onChange(of: viewModel.isFinished) {
                dismiss()
            }
            .alert(
                title(viewModel.alert),
                isPresented: .init(
                    get: { viewModel.alert != nil },
                    set: { isPresented in
                        guard !isPresented else { return }
                        viewModel.reduce(by: .dismissAlert)
                    }
                ),
                presenting: viewModel.alert,
                actions: { alert in
                    AlertActions(
                        alert: alert,
                        information: information,
                        reduce: viewModel.reduce(by:)
                    )
                },
                message: { alert in
                    Text(message(alert))
                }
            )
        }
    }

}

extension RecordScreen.Context {
    typealias Alert = RecordScreen.Status.Alert

    var information: RecordScreen.Information {
        .init(
            title: title,
            topic: topic,
            parties: parties.map(\.name)
        )
    }

    func title(_ alert: Alert?) -> String {
        switch alert {
            case .confirmCancel:        "녹음 취소"
            case .confirmSave:          "녹음 완료"
            case .permissionDenied:     "마이크 권한 필요"
            case .prepareFailed:        "녹음 준비 실패"
            case .saveFailed:           "녹음 저장 실패"
            case nil:                   ""
        }
    }

    func message(_ alert: Alert) -> String {
        switch alert {
            case .confirmCancel:        "녹음물은 저장되지 않습니다"
            case .confirmSave:          "녹음을 중지하고 녹음물을 저장하시겠습니까?"
            case .permissionDenied:     "설정 > Casual Conversation > 마이크를 허용해 주세요"
            case .prepareFailed:        "잠시 후 다시 시도해 주세요"
            case .saveFailed:           "녹음물을 저장하지 못했습니다"
        }
    }

}

extension RecordScreen.Context {

    struct AlertActions: View {
        @Environment(\.openURL) private var openURL

        let alert: Alert
        let information: RecordScreen.Information
        let reduce: (RecordScreen.Intent) -> Void

        var body: some View {
            switch alert {
                case .confirmCancel:
                    Button(
                        "삭제",
                        role: .destructive
                    ) {
                        reduce(.cancel)
                    }
                    Button(
                        "취소",
                        role: .cancel
                    ) {
                        reduce(.dismissAlert)
                    }

                case .confirmSave:
                    Button(
                        "취소",
                        role: .cancel
                    ) {
                        reduce(.dismissAlert)
                    }
                    Button(
                        "저장",
                        role: .destructive
                    ) {
                        reduce(.save(information))
                    }

                case .permissionDenied:
                    Button("설정으로 이동") {
                        openSettings()
                        reduce(.cancel)
                    }
                    Button(
                        "닫기",
                        role: .cancel
                    ) {
                        reduce(.cancel)
                    }

                case .prepareFailed, .saveFailed:
                    Button(
                        "닫기",
                        role: .cancel
                    ) {
                        reduce(.cancel)
                    }
            }
        }
    }

}

extension RecordScreen.Context.AlertActions {

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(url)
    }

}

#if DEBUG
#Preview {
    RecordScreen.Context(viewModel: .mock)
}
#endif
