---
paths:
  - "**/*.swift"
---

# TCA View의 상태 변경

View는 Store의 상태를 읽지만 명령형으로 직접 변경하지 않는다. 버튼, gesture, lifecycle처럼 사용자의 의도를 나타내는 변경은 Action을 보내고 Reducer가 State를 변경한다.

```swift
// ❌ View가 Store의 상태를 직접 변경
Button(
    action: { store.title = "" },
    label: {
        Image(systemName: "xmark.circle.fill")
    }
)

// ✅ 사용자의 의도를 Action으로 전달
Button(
    action: { store.send(.view(.clearTitleButtonTapped)) },
    label: {
        Image(systemName: "xmark.circle.fill")
    }
)
```

TextField 같은 SwiftUI 양방향 입력에는 `BindingAction`과 `BindingReducer`를 사용할 수 있다. `$store.title`은 State setter를 직접 호출하는 예외가 아니라 binding Action을 Store로 보내는 TCA 경로다.

```swift
@ObservableState
struct State: Equatable {
    var title = ""
}

enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case view(View)

    enum View {
        case clearTitleButtonTapped
    }
}

var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
        switch action {
            case .binding:
                return .none

            case .view(.clearTitleButtonTapped):
                state.title = ""
                return .none
        }
    }
}
```

## 하위 View의 Feature 경계

하위 View에서 setter가 발생한다는 이유만으로 반드시 Child Feature를 만들지는 않는다.

- 부모 상태를 표시하고 부모의 Action 한두 개만 보내면 부모 Store를 전달한다
- 하위 View가 상태와 행동을 소유하기 시작하면 `feature-composition.md`의 기준에 따라 Child Feature 분리를 판단한다

`ConversationInfoBox`처럼 제목·주제·참여자·편집 상태와 이를 변경하는 Action을 함께 소유하는 View는 Child Feature가 적합하다. `Scope` 조합 방식과 일반적인 분리 기준은 `feature-composition.md`를 따른다.
