---
name: add-repository-operation
description: Domain이 필요로 하는 데이터 동작 하나를 Repository 계약과 Data 구현에 추가한다. Repository 메서드 추가, 저장·조회 구현, DTO·Record 변환 요청에 사용한다. API부터 화면까지 연결하는 end-to-end 요청에는 단독으로 사용하지 않는다.
---

# Repository 동작 하나 추가

먼저 `../../rules/application/repository-boundary.md`와 관련 Domain·영속성 규칙을 읽는다.

## 입력

- 호출자가 필요로 하는 업무 동작
- Aggregate와 반환해야 할 최소 의미
- 사용할 API 또는 저장 소스

## 수행

1. 기존 Repository와 Aggregate 경계를 조사한다.
2. 기존 계약에 동작을 추가할지 새 Repository가 필요한지 판단한다.
3. Domain 계약에는 Domain 타입과 경계가 소유한 오류만 노출한다.
4. Data 구현에서 API·Record를 Domain 타입으로 변환한다.
5. 성공, 빈 결과와 오류를 호출자가 구분할 수 있게 유지한다.

## 제외

- 단순 전달만을 위한 Repository를 만들지 않는다.
- Usecase, 화면 상태와 Composition Root를 함께 수정하지 않는다.
- 다른 Aggregate의 저장 구조를 정리하지 않는다.

## 결과와 검증

- 조립 가능한 Repository 구현과 기술 독립적인 계약을 남긴다.
- 변환, 성공 결과와 실패 경로를 격리된 테스트로 검증한다.
