---
paths:
  - "**/*.swift"
---

# TCA Navigation 소유권

Navigation 컨테이너와 루트 화면의 책임이 다르면 타입을 분리한다.

- 컨테이너는 path와 push·pop 정책을 소유한다
- 루트 화면은 탭, 목록과 화면 내부 상태를 소유한다
- 컨테이너 이름을 화면 네임스페이스의 `Root`와 중복시키지 않는다

Navigation 전체를 TCA 상태 트리로 구성할지, 시스템 `NavigationStack`과 화면별 Store를 조합할지는 화면 간 상태 공유와 Dependency 수명 요구를 기준으로 정한다. 화면별 독립 Store를 선택하면 navigation 상태와 Child reducer 자동 조합을 함께 포기한다는 점을 명시한다.
