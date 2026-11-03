import ComposableArchitecture

extension AlertState where Action == ConversationDetailScreen.Root.Feature.Action.Alert {

    static var playbackInterrupted: Self {
        .init(
            title: {
                TextState("재생이 일시 정지되었습니다")
            },
            actions: {
                ButtonState(action: .close) {
                    TextState("닫기")
                }
                ButtonState(role: .cancel) {
                    TextState("확인")
                }
            },
            message: {
                TextState("다른 오디오 사용으로 재생이 중단되었습니다")
            }
        )
    }

    static func playbackFailed(message: String) -> Self {
        .init(
            title: {
                TextState("녹음 파일을 재생할 수 없습니다")
            },
            actions: {
                ButtonState(role: .cancel) {
                    TextState("확인")
                }
            },
            message: {
                TextState(message)
            }
        )
    }

}
