---
name: implement-application-operation
description: 하나의 애플리케이션 동작을 데이터 소스부터 소비 지점까지 end-to-end로 구현한다. API·Repository·Usecase·의존성 연결을 함께 요청하거나 새 기능의 전체 데이터 흐름을 만들어 달라는 요청에 사용한다. 특정 레이어 하나만 수정하는 요청에는 사용하지 않는다.
---

# 애플리케이션 동작 end-to-end 구현

이 스킬은 필요한 원자 스킬만 조합한다. 하위 스킬의 구현 절차를 여기서 반복하지 않는다.

## 1. 경로 결정

- 기존 API, Repository, Usecase와 Composition Root를 조사한다.
- 새 동작에 필요한 단계와 이미 준비된 단계를 구분한다.
- 업무 정책 없이 데이터 동작을 그대로 노출할 수 있으면 Usecase 단계를 생략한다.

## 2. 원자 스킬 적용

필요한 순서대로 해당 문서를 읽고 적용한다.

1. 외부 endpoint가 필요하면 `../add-api-endpoint/SKILL.md`
2. 데이터 경계가 필요하면 `../add-repository-operation/SKILL.md`
3. 업무 정책이나 조합이 필요하면 `../add-usecase-operation/SKILL.md`
4. 새 구현을 소비 지점에 연결하려면 `../wire-feature-dependency/SKILL.md`

## 3. 전체 검증

- 호출 흐름에 불필요한 전달 계층이 없는지 확인한다.
- 각 경계에서 외부 기술 타입이 새지 않는지 확인한다.
- 대표 사용자 동작을 통해 입력부터 결과 반영까지 검증한다.

커밋과 PR은 사용자가 함께 요청한 경우에만 해당 스킬로 별도 수행한다.
