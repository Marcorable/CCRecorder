---
paths:
  - "**/*.swift"
---

# Swift 동시성

## Actor 격리

- 타입이 `@MainActor`면 `MainActor.run`으로 다시 감싸지 않고 격리된 문맥에서 바로 상태를 변경한다
- 격리되지 않은 문맥에서 UI 상태를 바꿀 때만 `await MainActor.run`을 사용한다
- `Sendable` 경고를 피하기 위해 임의로 `Task.detached`를 추가하지 않는다

## 불필요한 Task를 만들지 않는다

이미 비동기 문맥이면 `await`로 직접 호출한다. `Task.detached { ... }.value`나 `Task { @MainActor in }`로 한 번 더 감싸지 않는다.
무거운 동기 작업은 호출부에서 임시 Task로 감싸지 말고 함수 자체를 `async`로 만든다.

```swift
// ✅
.task {
    let barcode = barcode
    image = await barcodeManager.barcode(barcode)
}

// ❌
.task {
    image = await Task.detached(priority: .userInitiated) {
        await barcodeManager.barcode(barcode)
    }.value
}
```

## Unstructured Task 경계

동기 진입점에서 unstructured `Task`가 꼭 필요하면 작업에 필요한 의존성과 입력을 시작 전에 지역 상수로 캡처한다. 상태 갱신과 오류 처리는 프로젝트가 선택한 아키텍처의 규칙을 따른다.
