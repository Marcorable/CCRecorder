---
paths:
  - "**/*.swift"
---

# SwiftUI 상태 조건과 리소스 경계

값이 불변이라는 이유만으로 View에 두지 않는다. 값이 상태 전환에 참여하는지, SwiftUI 리소스인지로 소유 위치를 정한다.

- 순서·선택·노출·활성화와 사용자 동작 판단에 쓰는 조건은 선택한 아키텍처의 상태 컨테이너가 enum, ID, Bool 같은 프레임워크 중립 타입으로 소유한다.
- `Asset`, `Color`, `Image`, `Font`, `LocalizedStringKey` 같은 최종 리소스 매핑은 View 계층이 소유한다.
- 상태 컨테이너가 리소스를 저장하려고 SwiftUI나 UI 리소스 모듈을 import하지 않는다.
- 상태 전환과 무관한 순수 장식 상수는 View에 둘 수 있다.

```swift
enum Step: CaseIterable, Hashable {
    case overview
    case input
    case result
}
```

상태 컨테이너는 `Step`의 순서와 선택을 알고, View는 각 `Step`을 실제 이미지나 색으로 해석한다. 리소스 배열의 위치를 상태 판단의 근거로 사용하지 않는다.
