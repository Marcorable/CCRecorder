---
paths:
  - "**/*.swift"
---

# 선언과 이름

## 타입

- class 는 기본으로 `final class` 로 쓴다
- 접근 수준을 의도대로 적는다. 밖에서 쓸 일이 없으면 `private`, 밖에서 읽기만 하면 `private(set)`

```swift
final class ItemStore {
    private let service: ItemService
    private(set) var items: [Item] = []
}
```

## `.init` 축약

타입이 문맥상 분명하면 `.init(...)` 으로 줄인다.

```swift
// ✅
configuration = .init(
    retryCount: 3,
    timeout: 10
)

// ❌
configuration = NetworkConfiguration(...)
```

## 인자 레이블

호출부가 구처럼 읽히게 레이블을 짓는다.

```swift
func reject(refund id: Int, reason: String)
func approved(refund: Refund) -> Bool

reject(refund: 42, reason: "재고 없음")
```

## Bool 이름

- 할 수 있는지: `isAbleTo~` — `isAbleToReject`, `isAbleToSubmit`
- 필요한지: `~Needs` — `authorizationNeeds`
- 파생 값은 저장하지 않고 computed property로 표현한다
