---
paths:
  - "**/*.swift"
---

# TCA Presentation

특정 화면에 속한 sheet, fullScreenCover와 alert는 그 화면 Feature가 상태와 생명주기를 소유한다.

```swift
@ObservableState
struct State: Equatable {
    @Presents var detail: DetailScreen.Root.Feature.State?
}

@CasePathable
enum Action: ViewAction {
    case view(View)
    case detail(PresentationAction<DetailScreen.Root.Feature.Action>)
}

var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
            case .view(.detailButtonTapped):
                state.detail = .init()
                return .none

            case .detail(.dismiss):
                return .send(.view(.reload))

            case .detail:
                return .none
        }
    }
    .ifLet(\.$detail, action: \.detail) {
        DetailScreen.Root.Feature()
    }
}
```

View는 scoped Store를 시스템 presentation API에 연결한다.

```swift
.sheet(
    item: $store.scope(
        state: \.detail,
        action: \.detail
    )
) { store in
    DetailScreen.Root(store: store)
}
```

- Entity Optional이나 Bool을 별도로 두고 수동 Binding으로 dismiss를 흉내 내지 않는다
- 자식은 `@Dependency(\.dismiss)`로 닫고 부모는 `.child(.dismiss)`에서 reload와 영속 상태 변경 같은 후처리를 한다
- 여러 탭이 같은 presentation을 띄우면 dismiss 후 현재 탭을 기준으로 필요한 목록만 갱신한다
- 화면 밖에서도 떠야 하는 전역 presentation만 앱 또는 navigation 컨테이너가 소유한다
- 자식 Feature의 Dependency와 실제 객체 수명은 `dependency.md`의 하위 Feature 규칙을 따른다

## Alert 상태

일반 alert도 presentation이므로 `@Presents`로 `AlertState` 자체를 소유한다. alert 문자열을 만들기 위한 `Failure` enum이나 별도 실패 상태를 중복해서 두지 않는다.

```swift
@Presents var alert: AlertState<Action.Alert>?

case let .response(.playbackFailed(error)):
    state.alert = .playbackFailed(
        message: error.localizedDescription
    )
    return .none
```

- Feature가 Domain 오류를 사용자에게 보여 줄 문자열로 결정한다
- `AlertState` factory는 표시할 문자열만 받아 Domain을 import하지 않는다
- 실패를 화면의 다른 요소가 표현하거나 재시도 정책에 사용한다면 별도 상태를 둘 수 있다
- 타입이 문맥상 분명한 factory 구현은 `Self { ... }`보다 `.init(...)`을 사용하고 여러 인자는 소괄호 안에서 한 줄에 하나씩 쓴다

## 테스트

부모 Feature 테스트에서 다음을 검증한다.

- 사용자 Action이 `@Presents` 상태를 생성한다
- dismiss가 상태를 제거한다
- dismiss 후 reload, AppStorage 갱신 같은 부모 후처리가 실행된다
- 자식이 사용하는 Dependency가 부모 Store 생성 지점에 빠짐없이 등록된다

비동기 응답 Action이 `Equatable`이 아니면 `TestStore.receive`에 case key path를 전달한다.

```swift
await store.receive(\.response.itemsLoaded) {
    $0.items = items
}
```
