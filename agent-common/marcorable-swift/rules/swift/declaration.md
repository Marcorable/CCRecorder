---
paths:
  - "**/*.swift"
---

# 선언과 이름

## 타입

- class 는 기본으로 `final class` 로 쓴다
- 접근 수준을 의도대로 적는다. 밖에서 쓸 일이 없으면 `private`, 밖에서 읽기만 하면 `private(set)`
- `public`은 다른 모듈이 사용하는 계약에만 붙인다. 같은 모듈의 화면이나 구현에서만 쓰는 타입은 기본 접근 수준을 유지한다
- 파일 이름이 나타내는 protocol이나 공개 계약을 위에 두고 concrete 구현과 private helper를 뒤에 둔다
- 모듈 경계를 넘는 오류는 호출자가 알 수 있는 공개 계약에 선언하고 concrete 타입의 내부 오류로 숨기지 않는다

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

## 지역 변수 이름

주변 문맥과 대입문의 출발점에서 대상이 분명하면 타입이나 긴 도메인 이름을 반복하지 않고 현재 역할을 표현한다.

```swift
// ✅
var updatingItem = state.conversation

// ❌
var conversation = state.conversation
```

## Bool 이름

- 할 수 있는지: `isAbleTo~` — `isAbleToReject`, `isAbleToSubmit`
- 필요한지: `~Needs` — `authorizationNeeds`
- 파생 값은 저장하지 않고 computed property로 표현한다
