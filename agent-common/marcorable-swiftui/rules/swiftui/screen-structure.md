---
paths:
  - "**/*.swift"
---

# SwiftUI 화면 구조

화면 하나는 `<Name>Screen` 네임스페이스 아래에 화면 전용 타입을 중첩한다.
화면을 그리는 최상위 SwiftUI View는 `<Name>Screen.Root`다.

```swift
enum SearchScreen {}

extension SearchScreen {

    struct Root: View {
        var body: some View { ... }
    }

}
```

- 화면 타입에 `View` 접미사를 붙이지 않는다
- 로직이 없는 화면은 네임스페이스와 `Root`만 만든다
- 상태·입력·비동기 동작을 담당하는 타입은 프로젝트가 선택한 아키텍처 팩에서 정의한다
- 독립적으로 진입하거나 presentation되는 화면 단위 폴더는 타입과 같은 `<Name>Screen`으로 명명한다
- `NavigationStack`, `Sheet` 같은 presentation 방식과 화면 내부의 `Root`, `Panel`, `Section` 폴더에는 `Screen` suffix를 붙이지 않는다

아키텍처를 바꿔도 Screen 이름, Root와 화면 전용 타입의 소유 관계는 유지할 수 있다.

## 앱 전체 표시 환경

색상 모드처럼 전체 화면이 상속해야 하는 SwiftUI 환경은 App의 런타임 조립 코드가 아니라 navigation을 구성하는 presentation root에 적용한다. 화면별로 달라지는 값만 개별 Screen에서 덮어쓴다.
