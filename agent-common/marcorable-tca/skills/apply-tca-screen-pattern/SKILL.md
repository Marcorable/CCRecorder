---
name: apply-tca-screen-pattern
description: 기존 화면의 위치와 진입 경로를 유지한 채 현재 UI 프레임워크에 맞는 TCA Feature와 Action·Reducer·Dependency 구조를 적용한다. UIKit·SwiftUI 화면 상태의 TCA 전환이나 Feature 구성 요청에 사용한다. 파일 이동, presentation 연결과 기존 TCA Feature의 child 분리에는 사용하지 않는다.
---

# TCA 화면 패턴 적용

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-tca/rules/architecture/feature-composition.md`
- `agent-common/marcorable-tca/rules/architecture/action-organization.md`
- `agent-common/marcorable-tca/rules/architecture/effect-routing.md`
- `agent-common/marcorable-tca/rules/architecture/reducer-decomposition.md`
- `agent-common/marcorable-tca/rules/architecture/dependency.md`
- `agent-common/marcorable-tca/rules/architecture/effect-lifecycle.md`

## 수행

1. 최상위 화면 상태와 사용자 시나리오를 Feature가 소유하게 한다. SwiftUI는 `<Name>Screen.Root.Feature`, UIKit은 기존 ViewController·Feature 배치를 유지한다.
2. Action을 발생 주체와 역할에 따라 구성하고 Reducer를 정책 단위로 나눈다.
3. 외부 동작은 `@Dependency` 계약으로 주입하고 Store 생성 지점에서 구현을 연결한다.
4. 장기 Effect의 시작, 취소와 자원 정리 경로를 대칭으로 만든다.
5. 대표 Action과 상태 전이를 `TestStore`로 검증한다.

화면 안에 독립적인 업무 경계가 이미 드러나면 이 스킬에 분리 절차를 섞지 않고 `agent-common/marcorable-tca/skills/extract-tca-child-feature/SKILL.md`를 이어서 사용한다.

## 제외

- 화면 파일을 다른 모듈로 이동하지 않는다.
- sheet·fullScreenCover·alert를 함께 재구성하지 않는다.
- 기존 TCA Feature의 일부를 child Feature로 추출하지 않는다.

## 결과와 검증

- View는 상태를 직접 바꾸지 않고 Action을 보낸다.
- Dependency 호출 경로와 Effect 종료 조건을 테스트한다.
