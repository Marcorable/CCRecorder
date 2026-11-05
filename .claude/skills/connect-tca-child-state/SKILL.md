---
name: connect-tca-child-state
description: 부모 Feature가 Source of Truth를 소유하면서 기존 TCA Child Feature와 상태를 양방향으로 주고받아야 할 때 입력과 출력 연결을 조합한다. 초기값·후속 Parent 입력과 Delegate 출력·부모 병합이 모두 필요한 편집 흐름에 사용한다. 한 방향만 필요하거나 새 Child Feature 추출, 상태 소유권 이동, Dependency Effect 분리에는 사용하지 않는다.
---

# TCA Child 상태 연결

다음 원자 스킬을 순서대로 적용한다.

- `../connect-tca-child-input/SKILL.md`
- `../connect-tca-child-output/SKILL.md`

## 입력

- 부모가 소유한 Source of Truth
- Child의 독립 업무에 필요한 투영 상태
- 부모에서 Child로 전달할 초기값과 후속 사건
- Child에서 부모로 전달할 의미 있는 결과

## 수행

1. `connect-tca-child-input`으로 부모에서 Child로 들어오는 초기·후속 입력을 연결한다.
2. `connect-tca-child-output`으로 Child의 의미 있는 결과와 부모 병합을 연결한다.
3. 부모 입력이 실제 업무 변경 없이 다시 Child 출력으로 반사되는 순환 경로가 없는지 확인한다.
4. 초기화, 후속 입력, Child 출력과 부모 병합을 하나의 대표 `TestStore` 시나리오로 검증한다.

## 제외

- 입력이나 출력 중 한 방향만 필요하면 해당 원자 스킬만 적용한다.
- 새 Child Feature를 만들거나 기존 업무를 Child로 옮기지 않는다.
- 부모와 Child 사이의 상태 소유자를 바꾸지 않는다.
- Child의 Dependency, Effect와 취소 범위를 함께 재구성하지 않는다.

## 완료 조건

- 부모→Child 입력과 Child→부모 출력 경로가 각각 하나다.
- mutable Entity의 복사본이 부모와 Child에 동시에 남지 않는다.
- 입력과 출력 사이에 의도하지 않은 순환이 없다.
- 대표 양방향 상태 전이 테스트가 통과한다.
