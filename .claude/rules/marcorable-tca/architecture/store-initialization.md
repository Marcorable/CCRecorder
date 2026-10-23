---
paths:
  - "**/*.swift"
---

# TCA Store 초기화

`Store`와 `TestStore`는 후행 클로저로 축약하지 않고 소괄호와 매개변수 레이블을 유지한다.

```swift
let store: StoreOf<RecordFeature> = .init(
    initialState: .init(),
    reducer: { RecordFeature() },
    withDependencies: {
        $0.recordUsecase = .live(service: MockRecorderService())
    }
)
```

- 타입이 문맥상 분명하면 `Store(...)`, `TestStore(...)`보다 `.init(...)`을 사용한다
- `initialState`, `reducer`, `withDependencies` 레이블을 생략하지 않는다
- `withDependencies`가 필요하지 않으면 해당 인자만 생략한다
- 실제 앱, Preview, 테스트에서 같은 초기화 문법을 사용한다
