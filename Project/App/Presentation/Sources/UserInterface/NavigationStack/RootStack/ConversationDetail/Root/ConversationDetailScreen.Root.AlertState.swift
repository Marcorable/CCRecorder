import ComposableArchitecture

extension AlertState where Action == ConversationDetailScreen.Root.Feature.Action.Alert {

    static func playbackFailed(
        _ failure: ConversationDetailScreen.PlaybackPanel.Feature.State.Failure
    ) -> Self {
        Self {
            TextState("녹음 파일을 재생할 수 없습니다")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        } message: {
            switch failure {
                case .fileNotFound:
                    TextState("녹음 파일을 찾을 수 없습니다")

                case .prepareFailed:
                    TextState("녹음 파일을 준비하지 못했습니다")
            }
        }
    }

}
