
# 여러 줄 View 호출의 modifier 정렬

여러 줄로 작성한 View 표현식에 modifier를 이어 붙일 때는 modifier의 `.`을 호출을 닫는 `)`와 같은 깊이에 둔다. modifier는 호출의 인자가 아니라, 완성된 View 표현식에 이어지는 체인임을 드러낸다.

```swift
// ✅
Factory.make(
    by: route,
    with: client
)
.navigationDestination(for: Route.self) { route in
    ...
}
.environment(viewModel)

// ❌
Factory.make(
    by: route,
    with: client
)
    .navigationDestination(for: Route.self) { route in
        ...
    }
```

표현식이 클로저나 다른 호출 안에 있으면 그 표현식의 시작 깊이를 기준으로 같은 원칙을 적용한다.

```swift
root: {
    Factory.make(
        by: .main,
        with: client
    )
    .navigationDestination(for: Route.self) { route in
        ...
    }
}
```

이 규칙은 여러 줄 호출 뒤에 이어지는 SwiftUI modifier의 관계만 다룬다. 한 줄 표현식에서 시작하는 일반 체인의 줄바꿈 방식이나 SwiftUI가 아닌 메서드 체인의 정렬까지 강제하지 않는다.

<!-- 근거: Marco가 여러 줄 Factory 호출 뒤 modifier를 호출 종료와 같은 깊이에 두는 방식을 직접 선택 -->
