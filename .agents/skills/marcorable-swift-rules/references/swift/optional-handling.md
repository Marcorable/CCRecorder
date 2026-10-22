
# Optional 처리

## 변환은 flatMap, 표시는 기본값

Optional 을 다른 값으로 바꿀 때는 `if let` 분기 대신 `flatMap` 을 쓰고, 화면에 보여줄 값은 `?? ""` 로 기본값을 준다.

```swift
// ✅
AWMText(
    viewModel.deliveryNotice.flatMap({ "· \($0)" }) ?? "",
    font: .thinBody
)

// ❌ 뷰 계층 안에서 분기
if let deliveryNotice = viewModel.deliveryNotice {
    AWMText("· \(deliveryNotice)", font: .thinBody)
}
```

단, 값이 없을 때 **뷰 자체가 없어야** 하면(레이아웃 공간까지 사라져야 하면) `if let` 을 쓴다.

## 표시용 ViewModel 프로퍼티

하위 View 의 `Model` 은 원본 Optional 을 필드에 그대로 둔다. 표시용 기본값은 ViewModel 의 computed property 에서 정하고, 뷰는 Optional 을 몰라도 되게 한다 (`agent-common/marcorable-swift/rules/architecture/section-subview.md`).

```swift
var representative: String { model.representative ?? "" }
```

## guard

`guard` 는 항상 여러 줄로 쓴다. 한 줄 `guard ... else { return }` 은 쓰지 않는다.

```swift
guard let martId = dependency.loginUsecase.martId else {
    return
}
```

조건이 여럿이면 `guard` 다음 줄부터 조건을 한 줄에 하나씩 쓰고, `else {` 는 새 줄에 둔다.

```swift
guard
    let martId = dependency.loginUsecase.martId,
    isAbleToSubmit
else {
    return
}
```

## nil 비교

Optional 이 있는지는 `!= nil` / `== nil` 로 쓴다. `.isNil` 같은 확장 프로퍼티는 쓰지 않는다. (QMarket `4684b6409` 리뷰 반영)

```swift
// ✅
if viewModel.point != nil, viewModel.barcode == nil { ... }

// ❌
if !viewModel.point.isNil, viewModel.barcode.isNil { ... }
```

## Bool Optional

`model?.flag == true ? .enabled : .disabled` 처럼 `== true` 로 비교한다.
분기가 여러 개면 `guard let model` 로 풀고 `switch` 한다.
