---
paths:
  - "**/*.swift"
---

# 섹션 서브뷰 구성

화면을 이루는 큰 영역(섹션, 보드)은 **부모 화면 타입 안에 중첩된 View** 로 만들고, 자기 ViewModel 과 Model 을 함께 가진다.

## 파일과 이름

- 파일명: `<부모>.<섹션>.swift` — 예) `MartInfoView.BusinessInfoSection.swift`, `BarcodeRegisterScreen.Board.swift`
- 위치: 부모 폴더의 `Subview/` (섹션이 여럿이면 `Subview/Section/`)
- 선언: `extension <부모> { struct <섹션>: View { ... } }`

## 한 파일 안의 구성 순서

```swift
extension MartInfoView {

    struct BusinessInfoSection: View {
        let viewModel: ViewModel          // 또는 @Environment(ViewModel.self)

        var body: some View { ... }
    }

}

extension MartInfoView.BusinessInfoSection {

    @Observable
    @MainActor
    final class ViewModel {
        var model: Model?

        init(model: Model? = nil) {
            self.model = model
        }
    }

    struct Model {                        // 화면에 필요한 값만, Domain Entity 아님
        let representative: String
        let businessRegistrationNumber: String
    }

}

extension MartInfoView.BusinessInfoSection.ViewModel {

    var representative: String { model?.representative ?? "" }

    var deliveryState: DeliveryState {      // case 만 고른다
        model?.isDeliveryEnabled == true ? .enabled : .disabled
    }

}

extension MartInfoView.BusinessInfoSection {

    func deliveryText(_ state: ViewModel.DeliveryState) -> String {   // 문구는 View 쪽
        switch state {
            case .enabled:
                "사용"

            case .disabled:
                "미사용"
        }
    }

}

#Preview { ... }
```

## 원칙

- **ViewModel 은 상태를 보관하고 case 만 고른다. 문구는 View 쪽에서 정한다.** `"사용"`, `"미사용"` 같은 문구를 ViewModel 이 만들지 않는다
- 문구는 View 의 extension 에서 case 를 `switch` 해 정한다. body 안에 삼항·분기로 늘어놓지 않는다
- 데이터 값을 그대로 보여줄 때 Optional 기본값(`model?.name ?? ""`)은 ViewModel computed property 에 둔다
- 상위 Model/ViewModel 이 섹션 ViewModel 을 소유하고, 데이터를 받으면 `model = .init(...)` 으로 갱신한다
- `Model` 은 Domain Entity 를 그대로 노출하지 않는다. 필요한 필드만 복사한다
- 섹션 하나에 `#Preview` 하나를 두고, 실제와 비슷한 샘플 값을 넣는다
- 두 화면 이상에서 같은 섹션이 쓰이면 공용 컴포넌트로 뺀다 (예: `BottomButtonSection`, `TextFieldSection`)

## View 나누기

View 를 나눌 때는 **중첩 View 타입**을 만든다. `func` 나 `@ViewBuilder var` 로 나누지 않는다. 중첩 View 는 필요한 값만 프로퍼티로 받는다.

```swift
// ✅
extension OrderRow {

    struct PriceLabel: View {
        let price: Int

        var body: some View { ... }
    }

}

// ❌
private func priceLabel() -> some View { ... }
@ViewBuilder private var priceLabel: some View { ... }
```
