
# SwiftUI 조건 분기 정규화

조건마다 같은 View와 modifier 구조를 반복하고 표시 값만 달라지면 구조는 한 번만 작성한다. 조건에 따라 달라지는 문자열, 색, 아이콘과 접근성 문구를 표시 값으로 계산한다.

```swift
VStack(alignment: .leading) {
    Text(content.title)
    Text(content.detail)
        .foregroundStyle(content.detailStyle)
}
```

레이아웃, 사용자 동작, 접근성 구조나 View 생명주기가 실제로 다르면 서로 다른 분기를 유지한다. 모양이 비슷하다는 이유만으로 의미가 다른 View를 하나로 합치지 않는다.

여러 표시에 공유되는 파생 값은 UI 전용 표시 입력에 둔다. View가 직접 사용하지 않는 중간 판정은 가능한 좁게 `private`으로 숨기고, Bool 프로퍼티를 연쇄적으로 늘리지 않는다.
