---
name: extract-tca-child-feature
description: 기존 TCA Feature의 독립 업무를 child Feature로 추출하고 Scope·Action·Effect·테스트를 연결한다. 비대한 Root에서 업무 상태를 분리하거나 여러 하위 View가 공유할 Store를 만들 때 사용한다. 화면 전체의 TCA 전환, 단순 View 분리와 presentation 연결에는 사용하지 않는다.
---

# TCA Child Feature 추출

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-tca/rules/architecture/child-feature-boundary.md`
- `agent-common/marcorable-tca/rules/architecture/feature-state-ownership.md`
- `agent-common/marcorable-tca/rules/architecture/child-feature-communication.md`
- `agent-common/marcorable-tca/rules/architecture/action-organization.md`
- `agent-common/marcorable-tca/rules/architecture/dependency.md`
- `agent-common/marcorable-tca/rules/architecture/effect-lifecycle.md`

## 경계 확인

- 분리할 업무의 State, Action, Dependency Effect와 취소 범위를 찾는다.
- View 계층이나 코드 길이가 아니라 상태와 생명주기 소유권이 독립되는지 확인한다.
- Root와 Child가 함께 변경할 mutable Entity가 있다면 단일 소유자를 정하고, Root가 유지할지 Child로 옮길지 결정한다.

독립 경계가 성립하지 않으면 Child Feature를 만들지 않고 같은 Feature 안의 reducer 함수나 파일만 분리한다.

## 수행

1. 대상 업무의 State와 Action을 Child Feature로 옮긴다.
2. 해당 업무가 직접 사용하는 Dependency, Effect와 취소 ID를 함께 옮긴다.
3. Root에 Child State와 Action case를 두고 `Scope`로 조합한다.
4. Root가 Source of Truth를 유지하면 필요한 연결 방향을 고른다.
   - Child 입력만 필요하면 `../connect-tca-child-input/SKILL.md`를 적용한다.
   - Child 출력만 필요하면 `../connect-tca-child-output/SKILL.md`를 적용한다.
   - 입력과 출력이 모두 필요하면 `../connect-tca-child-state/SKILL.md`를 적용한다.
5. Root에는 화면 전체의 presentation, navigation과 여러 Child를 잇는 상위 시나리오만 남긴다.
6. 같은 업무 상태를 사용하는 View에는 동일한 Child Store를 scope해 전달한다.
7. Child의 대표 상태 전이와, 출력이 있다면 Root의 delegate 조정 흐름을 각각 `TestStore`로 검증한다.

## 제외

- Root가 Child의 Dependency 호출이나 응답을 대신 전달하지 않는다.
- Root와 Child에 같은 mutable Entity를 복제하지 않는다.
- 관련 없는 presentation, navigation과 파일 위치를 함께 바꾸지 않는다.

## 완료 조건

- Root와 Child의 State 소유권이 겹치지 않는다.
- Child의 Effect 시작과 종료가 Child 경계에서 완결된다.
- 부모가 알아야 할 출력이 있다면 Root는 Child의 구현 세부가 아니라 의미 있는 `delegate` 사건에만 반응한다.
- Child와 Root의 책임을 나눈 테스트가 통과한다.
