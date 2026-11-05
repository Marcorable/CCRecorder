---
name: connect-tca-child-input
description: 부모 Feature가 소유한 Source of Truth를 기존 TCA Child Feature에 필요한 투영 상태로 연결한다. Child State 초기값이나 비동기 로드·외부 변경 뒤의 Parent 입력 경로를 구성할 때 사용한다. Child의 Delegate 출력, 새 Child Feature 추출, 상태 소유권 이동이나 Dependency Effect 분리에는 사용하지 않는다.
---

# TCA Child 입력 연결

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-tca/rules/architecture/feature-state-ownership.md`
- `agent-common/marcorable-tca/rules/architecture/child-feature-state-input.md`
- `agent-common/marcorable-tca/rules/architecture/parent-child-event.md`

## 입력

- 부모가 소유한 Source of Truth
- Child의 독립 업무에 필요한 값과 ID
- Child 생성 시 알 수 있는 값과 이후 도착하거나 바뀌는 값

## 수행

1. 부모가 Source of Truth의 유일한 변경 소유자인지 확인한다.
2. Child State를 Entity 복사본이 아니라 독립 업무에 필요한 값과 ID로 구성한다.
3. 생성 시 아는 값은 Child State 초기값으로 전달한다.
4. 이후 도착하거나 바뀌는 값은 의미 있는 `Parent` Action으로 전달하고 Child reducer가 해석하게 한다.
5. 초기 상태와 후속 입력에 따른 상태 전이를 `TestStore`로 검증한다.

## 제외

- Child의 변경 결과를 부모에 알리는 `Delegate` 출력은 구성하지 않는다.
- 새 Child Feature를 만들거나 기존 업무를 Child로 옮기지 않는다.
- 부모와 Child 사이의 상태 소유자를 바꾸지 않는다.
- Child의 Dependency, Effect와 취소 범위를 함께 재구성하지 않는다.

## 완료 조건

- mutable Entity의 복사본이 부모와 Child에 동시에 남지 않는다.
- 부모에서 Child로 들어오는 초기화와 후속 갱신 경로가 하나다.
- Child State는 독립 업무에 필요한 값만 가진다.
- 읽기 전용, 초기값 전용 또는 후속 갱신이 있는 입력에 독립 적용할 수 있다.
