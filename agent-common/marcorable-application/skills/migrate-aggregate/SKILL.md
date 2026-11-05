---
name: migrate-aggregate
description: 기존 데이터 구조의 Aggregate 하나를 기술 독립적인 Domain·Repository 경계로 점진적으로 전환한다. Clean Architecture 전환, SwiftData 모델 분리와 Repository migration, 레거시 저장 경계 교체 요청에 사용한다. 앱 전체 일괄 재구성에는 사용하지 않는다.
---

# Aggregate 하나 마이그레이션

이 스킬은 Aggregate 하나의 읽기와 쓰기를 완결된 단위로 전환한다.

## 1. 범위 결정

- 함께 일관성을 지켜야 하는 값, 불변 조건과 트랜잭션 단위로 Aggregate 후보를 정한다.
- 같은 사용자 동작에서 함께 생성·변경·삭제되지 않는 데이터는 별도 Aggregate 후보로 둔다.
- 현재 Source of Truth와 읽기·쓰기 소비 경로를 모두 찾는다.
- 인접 Aggregate와 공유하는 트랜잭션이 있으면 경계와 원자성 소유자를 먼저 명확히 한다.
- 경계가 불분명하면 타입 이동을 시작하지 않고 후보와 판단 근거를 제시한다.
- 변경할 타입, 조립 지점, 데이터 호환성과 검증 방법을 제시한다.

## 2. 원자 스킬 적용

필요한 문서만 읽고 적용한다.

1. 저장 모델이 Domain 역할을 겸하면 `../separate-persistence-model/SKILL.md`
2. 새 데이터 계약과 구현이 필요하면 `../add-repository-operation/SKILL.md`
3. 새 구현의 조립이 필요하면 `../wire-feature-dependency/SKILL.md`
4. 준비가 끝나면 `../switch-source-of-truth/SKILL.md`

## 3. 완료 조건

- Domain은 UI·저장·네트워크 기술을 알지 않는다.
- 선택한 Aggregate의 읽기와 쓰기가 하나의 Repository 경계를 사용한다.
- Data 변환과 대표 사용자 흐름이 검증됐다.
- 기존 데이터가 새 경계에서 복원되거나 명시적인 migration을 거친다.
- 기존 경로와 새 경로가 동시에 Source of Truth로 남지 않았다.

다른 Aggregate 정리와 커밋은 별도 요청 범위로 남긴다.
