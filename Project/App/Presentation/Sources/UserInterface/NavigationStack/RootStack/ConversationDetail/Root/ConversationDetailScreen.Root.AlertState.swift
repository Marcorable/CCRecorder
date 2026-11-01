import ComposableArchitecture

extension AlertState where Action == ConversationDetailScreen.Root.Feature.Action.Alert {

    static func playbackFailed(message: String) -> Self {
        Self {
            TextState("녹음 파일을 재생할 수 없습니다")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        } message: {
            TextState(message)
        }
    }

}
