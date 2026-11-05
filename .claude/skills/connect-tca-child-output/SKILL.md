---
name: connect-tca-child-output
description: 기존 TCA Child Feature의 변경·완료·선택 결과를 의미 있는 Delegate 사건으로 내보내 부모가 소유한 Source of Truth에 연결한다. Child 출력과 부모 병합 경로를 구성할 때 사용한다. 부모에서 Child로 들어오는 입력, 새 Child Feature 추출, 상태 소유권 이동이나 Dependency Effect 분리에는 사용하지 않는다.
---

# TCA Child 출력 연결

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-tca/rules/architecture/feature-state-ownership.md`
- `agent-common/marcorable-tca/rules/architecture/child-feature-communication.md`
- `agent-common/marcorable-tca/rules/architecture/action-organization.md`

## 입력

- Child가 완료하거나 변경한 독립 업무
- 부모가 알아야 할 의미 있는 결과와 최소한의 값 또는 ID
- 부모가 소유한 Source of Truth의 병합 지점

## 수행

1. 부모가 결과를 알아야 하며 Source of Truth의 변경 소유자인지 확인한다.
2. 구현 세부사항이 아니라 변경·완료·선택 같은 의미로 `Delegate` Action을 정의한다.
3. Child reducer가 의미 있는 시점에 필요한 값 또는 ID만 담아 `Delegate`를 보낸다.
4. 부모 reducer가 `Delegate`를 받아 자신의 Source of Truth에 결과를 병합한다.
5. Child 출력과 부모 병합 상태 전이를 `TestStore`로 검증한다.

## 제외

- 부모에서 Child로 들어오는 초기값이나 `Parent` 입력은 구성하지 않는다.
- 새 Child Feature를 만들거나 기존 업무를 Child로 옮기지 않는다.
- 부모와 Child 사이의 상태 소유자를 바꾸지 않는다.
- Child의 Dependency, Effect와 취소 범위를 함께 재구성하지 않는다.

## 완료 조건

- Child에서 부모로 나가는 출력 경로가 하나다.
- 부모는 내부 Action이 아니라 의미 있는 `Delegate`에만 반응한다.
- Child는 부모 상태의 구조나 병합 구현을 알지 않는다.
- 출력이 없는 읽기 전용 Child에는 이 스킬을 적용하지 않는다.
