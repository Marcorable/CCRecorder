---
paths:
  - "**/*App.swift"
  - "**/*Factory*.swift"
  - "**/*Container*.swift"
  - "**/Project.swift"
---

# Composition Root 경계

- App의 조립 지점에서 실행 환경과 구체 구현을 선택한다
- 인프라의 초기화 시점과 수명은 인프라를 만든 조립 지점이 소유한다
- Factory는 API Client, 저장 Container 같은 구체 타입을 감추고 상위 레이어에는 계약을 반환할 수 있다
- Repository에는 실제로 사용하는 Context, Container, Client만 주입한다
- 화면 상태에는 표시와 사용자 상호작용에 필요한 값만 두고 인프라 수명을 맡기지 않는다
- Preview와 테스트는 같은 계약의 대체 구현을 별도로 조립한다

## 사용자 설정의 적용 경계

- Feature는 사용자가 선택한 설정값과 변경 의도를 소유한다
- 앱 전체의 표시 환경은 모든 push, sheet와 alert가 상속할 수 있는 presentation root에 적용한다
- `UIApplication` 같은 런타임 객체를 바꾸는 효과는 App 진입점이나 Composition Root에서 적용한다
- 런타임 설정은 해당 설정 화면을 열지 않아도 저장된 초기값이 앱 시작 시 반영되어야 한다

기존 프로젝트에 명확한 조립 지점이 있으면 새로운 DI 프레임워크나 전역 Container를 추가하지 않고 그 경계를 따른다.
