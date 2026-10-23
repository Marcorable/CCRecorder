---
paths:
  - "**/*.swift"
---

# SwiftUI 화면 구조

화면 하나는 `<Name>Screen` 네임스페이스 아래에 화면 전용 타입을 중첩하고, 파일은 도트 이름으로 나눈다.
화면을 그리는 최상위 SwiftUI View는 `<Name>Screen.Root`다.

```swift
enum SearchScreen {}

extension SearchScreen {

    struct Root: View {
        var body: some View { ... }
    }

}
```

- 화면 폴더와 컴포넌트 배치는 `agent-common/marcorable-swiftui/rules/swiftui/ui-layout.md`를 따른다
- 화면 타입에 `View` 접미사를 붙이지 않는다
- 로직이 없는 화면은 네임스페이스와 `Root`만 만든다
- 상태·입력·비동기 동작을 담당하는 타입은 프로젝트가 선택한 아키텍처 팩에서 정의한다

아키텍처를 바꿔도 Screen 이름, Root, 화면 전용 타입의 중첩과 파일 배치는 유지할 수 있다.
