---
paths:
  - "**/*.swift"
---

# TCA Child Feature 상태 입력

부모가 mutable Entity의 Source of Truth를 소유하면 Child State에 같은 Entity를 복제하지 않는다. Child에는 독립 업무가 실제로 사용하는 값만 투영한다.

```swift
@ObservableState
struct State: Equatable {
    var title = ""
    var topic = ""
    var rows: [Row] = []
}
```

부모가 Child를 만들 때 값을 알고 있으면 `State` 초기값으로 전달한다. 비동기 조회 뒤 값이 생기거나 이후 갱신되면 Child의 `Parent` Action으로 사건과 투영한 값을 전달하고, Child reducer가 자신의 State를 갱신한다.

```swift
enum Parent {
    case contentLoaded(
        title: String,
        topic: String
    )
}

case .parent(.contentLoaded(let title, let topic)):
    state.title = title
    state.topic = topic
    return .none
```

- Entity 전체를 편의상 전달하지 말고 Child가 사용하는 값, ID와 Child 전용 값 타입만 전달한다
- 부모에서 Child로 들어오는 변환과 갱신 경로를 하나로 유지한다
- 부모 reducer가 Child의 내부 필드를 여러 곳에서 직접 고치지 않고, 생성 시 초기화하거나 Child의 `Parent` Action으로 갱신한다

Child가 Entity의 유일한 변경 소유자라면 이 규칙을 적용하지 않고 `feature-state-ownership.md`에 따라 소유권 자체를 Child로 옮긴다.

비동기 로드와 후속 변경 사건 전달은 `parent-child-event.md`를 따른다.
