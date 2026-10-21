---
paths:
  - "**/*.swift"
---

# 인자 줄바꿈

인자가 **두 개 이상**이면 레이블 유무와 상관없이 **첫 인자부터** 줄을 바꿔 한 줄에 하나씩 쓰고, 닫는 괄호는 따로 한 줄에 둔다.

```swift
// ✅
.frame(
    maxWidth: .infinity,
    alignment: .leading
)

AWMText(
    "사업자 정보",
    font: .emphasisText
)

// ❌
.frame(maxWidth: .infinity, alignment: .leading)
```

## 예외

인자가 하나뿐일 때만 한 줄로 쓴다: `.padding(24)`, `QPDivider(8)`

```swift
// ✅
.padding(
    .horizontal,
    16
)

VStack(
    alignment: .leading,
    spacing: 24
) {
    ...
}

// ❌ 짧아도 한 줄로 쓰지 않는다
.padding(.horizontal, 16)
VStack(alignment: .leading, spacing: 24) {

// ❌ 첫 인자를 여는 괄호 옆에 두지 않는다
AWMText("사업자 정보",
        font: .emphasisText)
```

클로저 인자도 같은 규칙을 따른다. 앞선 클로저의 닫는 중괄호와 다음 레이블을 같은 줄에 쓰지 않는다.

```swift
// ✅
Button(
    action: {
        isPresented.toggle()
    },
    label: {
        Text("앱 시작하기")
    }
)

// ❌
Button(
    action: {
        isPresented.toggle()
    }, label: {
        Text("앱 시작하기")
    }
)
```

## 여러 줄 문자열

긴 안내 문구는 배열로 나눈 뒤 `joined` 한다. 줄바꿈이 필요하면 `separator: "\n"`,
한 문장을 이어 붙이면 `separator: " "` 를 쓴다. 한글 문구가 어절 단위로 잘리면 `.charWrappable` 을 붙인다.

```swift
toolTip: [
    "저울에서 스티커 발행 시, 신규 상품은 파트너스에",
    "자동 등록되며 기존 상품은 가격이 자동 업데이트됩니다."
].joined(separator: " ").charWrappable
```

## 삼항 연산자

삼항 연산자는 줄을 바꾼다. 조건 다음 줄에 `? 값`, 그다음 줄에 `: 값` 을 쓴다.

```swift
// ✅
let state: DeliveryState = model?.isDeliveryEnabled == true
    ? .enabled
    : .disabled

// ❌
let state: DeliveryState = model?.isDeliveryEnabled == true ? .enabled : .disabled
```
