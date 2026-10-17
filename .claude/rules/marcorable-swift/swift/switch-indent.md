---
paths:
  - "**/*.swift"
---

# switch 들여쓰기

`case` 는 `switch` 보다 **한 단계 들여쓴다.** Xcode 기본값(`case` 를 `switch` 와 같은 열에 두기)과 다르다.

```swift
// ✅
switch result {
    case .success(let content):
        apply(content)

    case .failure(let error):
        Factory.logger.log(
            of: .error,
            error.debugDescription
        )
}

// ❌ Xcode 기본값
switch result {
case .success(let content):
    apply(content)
case .failure(let error):
    ...
}
```

## 세부

- `case` 블록이 두 개 이상이고 본문이 있으면 **case 사이에 빈 줄**을 둔다
- 중첩 switch 도 같은 규칙을 그대로 적용한다
- 값만 돌려주는 짧은 switch 표현식은 열을 맞춰 한 줄로 쓴다

```swift
switch $0.deliveryContract {
    case .hatCall:                  "햇배달 호출"
    case .hatContract, .onlyHat:    "햇배달 지입"
    case .inHouse:                  nil
}
```

- 아무 일도 하지 않는 case 는 `break` 로 명시한다
