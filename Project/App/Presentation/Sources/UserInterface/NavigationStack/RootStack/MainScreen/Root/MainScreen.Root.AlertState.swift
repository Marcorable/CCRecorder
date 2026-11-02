
import ComposableArchitecture

extension AlertState where Action == MainScreen.Root.Feature.Action.Alert {

    static var conversationLoadFailed: Self {
        retryAlert(
            title: "대화 목록 불러오기 실패",
            retryAction: .retryConversationLoad
        )
    }

    static var conversationDeleteFailed: Self {
        failureAlert(
            title: "대화 삭제 실패",
            message: "대화 또는 녹음 파일을 삭제하지 못했습니다"
        )
    }

    static var noteLoadFailed: Self {
        retryAlert(
            title: "노트 불러오기 실패",
            retryAction: .retryNoteLoad
        )
    }

    static var noteDeleteFailed: Self {
        failureAlert(
            title: "노트 삭제 실패",
            message: "잠시 후 다시 시도해 주세요"
        )
    }

    private static func retryAlert(
        title: String,
        retryAction: Action
    ) -> Self {
        .init(
            title: {
                TextState(title)
            },
            actions: {
                ButtonState(action: retryAction) {
                    TextState("다시 시도")
                }
                ButtonState(role: .cancel) {
                    TextState("취소")
                }
            },
            message: {
                TextState("잠시 후 다시 시도해 주세요")
            }
        )
    }

    private static func failureAlert(
        title: String,
        message: String
    ) -> Self {
        .init(
            title: {
                TextState(title)
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
