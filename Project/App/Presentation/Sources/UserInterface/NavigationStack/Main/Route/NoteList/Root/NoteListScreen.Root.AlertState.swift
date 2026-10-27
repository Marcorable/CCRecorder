
import ComposableArchitecture

extension AlertState where Action == NoteListScreen.Root.Feature.Action.Alert {

    static var loadFailed: Self {
        Self {
            TextState("노트 불러오기 실패")
        } actions: {
            ButtonState(action: .retryButtonTapped) {
                TextState("다시 시도")
            }
            ButtonState(role: .cancel) {
                TextState("취소")
            }
        } message: {
            TextState("잠시 후 다시 시도해 주세요")
        }
    }

    static var deleteFailed: Self {
        Self {
            TextState("노트 삭제 실패")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        } message: {
            TextState("잠시 후 다시 시도해 주세요")
        }
    }

}
