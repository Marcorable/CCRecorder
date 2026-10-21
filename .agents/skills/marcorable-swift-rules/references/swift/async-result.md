
# 비동기 호출과 Result 처리

Usecase 는 `async -> Result<T, Error>` 를 돌려준다 (작성 방식은 `usecase-repository.md`). 호출은 다음 순서로 쓴다.

1. `guard` 로 필요한 값(예: `martId`)을 먼저 확인한다
2. `Task` 밖에서 의존성과 입력값을 **지역 상수로 꺼낸다**
3. `Task` 안에서 `await` 하고 `switch result` 로 처리한다
4. 실패는 `Factory.logger.log(of: .error, ...)` 로 남긴다

```swift
private func fetchPOSInfo() {
    let mainUsecase = dependency.mainUsecase

    guard let martId = dependency.loginUsecase.martId else {
        return
    }

    Task {
        let result = await mainUsecase.fetchPosInfo(martId: martId)

        await MainActor.run { [weak self] in
            switch result {
                case .success(let posInfo):
                    self?.posInfoSectionViewModel.model = .init(...)

                case .failure(let error):
                    Factory.logger.log(
                        of: .error,
                        "posInfo fetching failed: \(error)"
                    )
            }
        }
    }
}
```

## 메인 스레드

- 타입이 `@MainActor` 면 `MainActor.run` 없이 바로 대입한다
- 아니면 `await MainActor.run { [weak self] in ... }` 로 감싼다
- Combine 바인딩은 `.receive(on: DispatchQueue.main)` 후 `.assign(to: &$property)` 를 쓴다

## Task 를 겹쳐 쓰지 않는다

이미 비동기 문맥이면 `await` 로 바로 부른다. `Task.detached { ... }.value` 나 `Task { @MainActor in }` 로 한 번 더 감싸지 않는다.
무거운 동기 작업은 호출부에서 감싸지 말고 **함수 자체를 `async` 로** 만든다. (QMarket `4684b6409` → `034098416` 리뷰 반영)

```swift
// ✅
.task {
    let barcode = viewModel.barcode
    self.image = await barcodeManager.barcode(barcode)
}

// ❌
.task {
    let image = await Task.detached(priority: .userInitiated) {
        await barcodeManager.barcode(viewModel.barcode)
    }.value
    self.image = image
}
```

## Entity → 표시 Model 변환

Domain Entity 를 그대로 뷰에 넘기지 않는다. 섹션 ViewModel 의 `Model` 로 `.init(...)` 변환해 넣는다.
