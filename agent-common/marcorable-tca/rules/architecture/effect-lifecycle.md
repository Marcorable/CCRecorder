---
paths:
  - "**/*.swift"
---

# TCA Effect 생명주기

화면 생명주기보다 오래 실행될 수 있는 Effect에는 명시적인 취소 ID를 붙인다.

```swift
return .run { send in
    let value = try await dependency.prepare()
    try Task.checkCancellation()
    await send(.response(.prepared(value)))
}
.cancellable(
    id: CancelID.prepare,
    cancelInFlight: true
)
```

- 화면 종료·취소·설정 이동 같은 모든 종료 경로에서 관련 Effect를 취소한다
- 취소 ID는 해당 Feature 안에 `private enum CancelID`로 둔다
- 권한 요청처럼 suspension이 있는 Dependency는 await 직후 취소를 확인하고 파일·세션 같은 자원을 만들기 전에 중단한다
- 일부 자원을 만든 뒤 실패하거나 취소될 수 있으면 Dependency가 정리 책임을 가진다
- 늦게 도착한 Response가 종료된 State를 되살리지 않도록 terminal 상태를 확인한다
- 준비 중 종료, 늦은 Response, 자원 정리를 함께 검증하는 회귀 테스트를 둔다
