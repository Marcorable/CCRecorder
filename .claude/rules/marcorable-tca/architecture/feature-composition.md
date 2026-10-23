---
paths:
  - "**/*.swift"
---

# TCA Feature 구성

화면은 `<Name>Screen` 네임스페이스 아래 `Root`와 `Root.Feature`로 구성한다. 화면 안에서만 쓰는 타입은 사용하는 State 또는 Feature에 중첩한다.

```swift
enum RecordScreen {}

extension RecordScreen {

    struct Root: View {
        let store: StoreOf<Feature>
    }

}

extension RecordScreen.Root {

    @Reducer
    struct Feature {
        var body: some ReducerOf<Self> { ... }
    }

}

extension RecordScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        var phase: Phase = .idle

        enum Phase: Equatable {
            case idle
            case recording
        }
    }

    private enum CancelID {
        case recording
    }

}
```

- 화면 전용 상태 구분 타입은 `State`에 중첩한다
- Effect 취소 식별자는 사용하는 `Feature`에 `private`으로 중첩한다
- 화면 밖에서도 재사용하는 Entity·Usecase·Repository 타입은 Screen에 중첩하지 않는다
- State initializer가 저장 프로퍼티를 그대로 대입하기만 하면 프로퍼티 기본값과 합성 initializer를 사용한다

## 하위 View와 Child Feature

하위 View가 부모 상태를 표시하고 부모 Action만 보낸다면 부모 Store를 전달한다. 중간 List가 있더라도 별도 상태와 생명주기가 없다면 Store 전달만 담당하고 Feature를 추가하지 않는다.

하위 View가 다음 책임 중 하나를 소유하면 Child Feature로 분리하고 `Scope`로 조합한다.

- 자체 State와 Action
- 독립적인 바인딩·검증
- 고유한 Effect 또는 취소 범위
- 독립 테스트 가치

```swift
Scope(
    state: \.conversationInfo,
    action: \.conversationInfo
) {
    ConversationInfoFeature()
}
```

Child Feature 분리는 View 계층의 깊이가 아니라 상태와 생명주기의 소유권으로 결정한다.
