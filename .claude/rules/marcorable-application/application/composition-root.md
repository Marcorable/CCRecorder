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

기존 프로젝트에 명확한 조립 지점이 있으면 새로운 DI 프레임워크나 전역 Container를 추가하지 않고 그 경계를 따른다.
