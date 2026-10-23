
# 클로저 표기

## 변환 연산자는 소괄호 안에

값을 바꾸거나 찾아서 돌려주는 연산자는 클로저를 **소괄호 안에** 넣는다.
`map`, `compactMap`, `flatMap`, `filter`, `reduce`, `sorted(by:)`, `first(where:)`, `contains(where:)`, `allSatisfy` 등이다.
체이닝은 연산자마다 줄을 바꾼다.

클로저도 인자 하나로 센다. 다른 인자와 함께 받으면 `agent-common/marcorable-swift/rules/swift/argument-wrapping.md` 대로 첫 인자부터 한 줄에 하나씩 쓴다.

```swift
// ✅
menuPublisher
    .map({
        $0.filter({ $0 != .myReview })
    })
    .compactMap({ $0 })

phoneNumber.flatMap({ "연동 번호 \($0.maskedPhoneNumber)" }) ?? ""

items.first(where: { $0.isSelected })

prices.reduce(
    0,
    { $0 + $1 }
)

// ❌
viewModel.$menus.map { $0.filter { $0 != .myReview } }
items.first { $0.isSelected }
prices.reduce(0) { $0 + $1 }
```

클로저 본문이 여러 줄이어도, 주변 레거시 코드가 후행 클로저를 써도 소괄호로 쓴다.

## 그 밖의 클로저는 후행 클로저

변환 연산자가 아닌 블록 구조의 클로저는 후행 클로저로 쓴다. 나머지 인자는 소괄호 안에 쓴다.

- SwiftUI content — `VStack { }`, `ForEach { }`, `.overlay { }`, `#Preview { }`
- SwiftUI 동작 modifier — `.onTapGesture { }`, `.onAppear { }`, `.task { }`, `.onChange(of:) { }`
- 비동기 — `Task { }`, `Task.detached { }`, `MainActor.run { }`, `withAnimation { }`
- Combine 구독 — `.sink { [weak self] in }`
- UIKit 설정 — Then 의 `.do { }`, `.then { }`, SnapKit 의 `snp.makeConstraints { }`
- 부수 효과 반복 — `forEach { }`

```swift
// ✅
VStack(
    alignment: .leading,
    spacing: 24
) {
    ...
}

Task(priority: .userInitiated) {
    ...
}

statePublisher
    .sink { [weak self] state in
        ...
    }
    .store(in: &cancellables)

// ❌
VStack(
    alignment: .leading,
    spacing: 24,
    content: {
        ...
    }
)

Task(operation: {
    ...
})

viewModel.$state.sink(receiveValue: { [weak self] state in ... })
```

## 클로저를 여러 개 받는 호출

클로저를 **두 개 이상** 받으면 다중 후행 클로저를 쓰지 않고 레이블을 살려 모두 소괄호 안에 쓴다.

```swift
// ✅
Button(
    action: {
        ...
    },
    label: {
        ...
    }
)

// ❌
Button(
    action: {
        ...
    }, label: {
        ...
    }
)

Button { ... } label: { ... }
```

<!-- 근거: Marco 가 직접 명시한 Swift 클로저 표기 규칙 -->

## 메서드 참조

클로저가 메서드 하나만 부르면 메서드 참조로 넘긴다.

```swift
.sink(receiveValue: handle(_:))
```
