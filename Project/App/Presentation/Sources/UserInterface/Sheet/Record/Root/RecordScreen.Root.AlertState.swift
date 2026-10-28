
import ComposableArchitecture

extension AlertState where Action == RecordScreen.Root.Feature.Action.Alert {

    static var confirmCancel: Self {
        Self {
            TextState("녹음 취소")
        } actions: {
            ButtonState(
                role: .destructive,
                action: .cancelConfirmed
            ) {
                TextState("삭제")
            }
            ButtonState(role: .cancel) {
                TextState("취소")
            }
        } message: {
            TextState("녹음물은 저장되지 않습니다")
        }
    }

    static var confirmSave: Self {
        Self {
            TextState("녹음 완료")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("취소")
            }
            ButtonState(
                role: .destructive,
                action: .saveConfirmed
            ) {
                TextState("저장")
            }
        } message: {
            TextState("녹음을 중지하고 녹음물을 저장하시겠습니까?")
        }
    }

    static var permissionDenied: Self {
        Self {
            TextState("마이크 권한 필요")
        } actions: {
            ButtonState(action: .openSettingsTapped) {
                TextState("설정으로 이동")
            }
            ButtonState(
                role: .cancel,
                action: .closeAfterFailure
            ) {
                TextState("닫기")
            }
        } message: {
            TextState("설정 > Casual Conversation > 마이크를 허용해 주세요")
        }
    }

    static var prepareFailed: Self {
        Self {
            TextState("녹음 준비 실패")
        } actions: {
            ButtonState(
                role: .cancel,
                action: .closeAfterFailure
            ) {
                TextState("닫기")
            }
        } message: {
            TextState("잠시 후 다시 시도해 주세요")
        }
    }

    static var saveFailed: Self {
        Self {
            TextState("녹음 저장 실패")
        } actions: {
            ButtonState(
                role: .cancel,
                action: .closeAfterFailure
            ) {
                TextState("닫기")
            }
        } message: {
            TextState("녹음물을 저장하지 못했습니다")
        }
    }

}
