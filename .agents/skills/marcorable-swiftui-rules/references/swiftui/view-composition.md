
# SwiftUI View 구성

화면을 이루는 큰 영역(`Section`, `Board`, `Panel`)과 반복 표시 단위(`Row`)는 부모 화면 타입 안에 중첩한다.

- 파일명은 `<부모>.<하위 View>.swift`로 짓는다
- 화면 폴더 아래 하위 View 이름의 폴더에 둔다. `Subview/` 중간 폴더는 만들지 않는다
- 입력이 없는 정적 View에 빈 상태 컨테이너나 보조 타입을 만들지 않는다
- 데이터나 동작과 무관한 고정 문구와 컴포넌트 구성은 View에 둔다
- 표시 포맷과 파생 값의 위치는 선택한 아키텍처가 정한다. View body 안에서 원본 Domain Entity를 반복해서 해석하지 않는다
- 화면 전용 View와 공용 Component의 경계는 `agent-common/marcorable-swiftui/rules/swiftui/ui-layout.md`를 따른다
- 하위 View마다 실제와 비슷한 Preview를 둔다

View를 나눌 때는 함수나 `@ViewBuilder` 연산 프로퍼티 대신 중첩 View 타입을 만든다.

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

표현만 담당하는 공용 Component는 값과 동작 클로저를 받는다. 독립적인 상태, 비동기 동작과 생명주기가 필요하면 단순 Component가 아니라 선택한 아키텍처의 하위 기능으로 구성한다.
