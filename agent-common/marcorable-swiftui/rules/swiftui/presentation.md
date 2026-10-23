---
paths:
  - "**/*.swift"
---

# 상태 기반 Presentation

화면 전환과 presentation은 명령형 호출보다 상태로 표현한다.

- `sheet(item:)`, `fullScreenCover(item:)`, `navigationDestination(item:)`처럼 목적지를 값으로 나타낼 수 있는 API를 우선한다
- 목적지가 여러 개면 Bool을 늘리지 않고 식별 가능한 enum 또는 선택한 아키텍처의 destination 상태로 표현한다
- 값 전체가 식별자인 enum·불변 값 타입은 프로젝트의 `IdentifiableFeature` 또는 표준 `Identifiable` 구현을 사용한다
- View는 상태에 맞는 destination을 선언적으로 고른다
- 상태를 누가 소유하고 어떻게 변경하는지는 선택한 아키텍처 팩에서 정한다
