---
name: replace-tca-entity-route-with-id
description: TCA Detail의 route나 presentation state가 전달하는 Domain Entity를 Entity.ID와 진입 시 조회 흐름으로 전환한다. Navigation Hashable 때문에 Entity 전체를 전달하거나 오래된 스냅샷 대신 최신 원본 조회가 필요한 요청에 사용한다. 단순 화면 마이그레이션이나 스냅샷 전달을 유지할 때는 사용하지 않는다.
---

# TCA Entity 진입값을 ID로 전환

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-application/rules/application/repository-boundary.md`
- `agent-common/marcorable-application/rules/application/usecase.md`
- `agent-common/marcorable-tca/rules/architecture/destination-input.md`
- `agent-common/marcorable-tca/rules/architecture/dependency.md`
- `agent-common/marcorable-tca/rules/architecture/effect-lifecycle.md`

## 수행

`destination-input` 규칙에 따라 최신 원본 조회가 필요한 경우에만 전환한다.

1. 호출자가 필요로 하는 ID 단건 조회를 Repository 계약과 구현에 추가한다.
2. Usecase가 Repository 오류를 프로젝트의 Domain 오류 흐름에 맞게 변환하게 한다.
3. TCA Dependency client에 단건 조회 endpoint를 추가한다.
4. Route, presentation state와 부모 delegate가 Entity 대신 `Entity.ID`를 전달하게 한다.
5. Detail State가 ID, 조회 결과와 로딩 실패 상태를 소유하게 한다.
6. 화면 진입 Action에서 조회를 시작하고 Entity가 필요한 후속 Effect는 조회 성공 뒤 실행한다.
7. View에 로딩, 조회 실패와 미존재 상태를 표현한다.

Preview는 ID로 State를 만들고 조회 Dependency가 샘플 Entity를 반환하게 한다.

## 검증

- Repository 단건 조회의 성공과 미존재를 검증한다.
- Usecase의 성공과 Data 오류 변환을 검증한다.
- Detail 진입 시 조회, 실패와 미존재 상태를 `TestStore`로 검증한다.
- 다른 화면의 Entity 전달이나 관련 없는 navigation 구조가 바뀌지 않았는지 확인한다.

Repository·Usecase 추가와 Detail 전환은 검토 가능한 별도 커밋으로 나눌 수 있다. 커밋 자체는 요청받았을 때만 수행한다.
