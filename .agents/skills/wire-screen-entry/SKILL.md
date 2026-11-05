---
name: wire-screen-entry
description: 이미 구현된 UIKit·SwiftUI 화면을 기존 navigation·route·factory에 등록해 실제 진입 경로와 연결한다. 새 화면 등록, route 추가, 화면 Factory 연결 요청에 사용한다. 화면 내부 상태 관리나 UI 구현 요청에는 사용하지 않는다.
---

# 화면 진입 연결

현재 화면이 UIKit인지 SwiftUI인지와 앱이 선택한 navigation 경계를 먼저 확인한다.

## 수행

1. 화면을 띄우는 기존 navigation 경계와 같은 UI 프레임워크의 유사한 진입 사례를 찾는다.
2. route, destination, coordinator, 화면 Factory 중 프로젝트가 사용하는 최소 지점만 수정한다.
3. 필요한 의존성을 기존 Composition Root에서 전달한다.
4. 레거시 진입점이 남아야 하면 새 경계로 위임하고 중복 생성은 피한다.
5. 실제 사용자 경로로 화면을 열고 닫아 확인한다.

## 제외

- 새로운 navigation 프레임워크를 도입하지 않는다.
- 화면 내부 상태와 presentation 소유권을 바꾸지 않는다.
- 관련 없는 route 이름을 정리하지 않는다.

## 결과와 검증

- 앱의 기존 진입 경로에서 화면이 한 번만 생성된다.
- 필요한 의존성과 dismiss·back 동작이 현재 UI 프레임워크의 수명에 맞게 연결된다.
