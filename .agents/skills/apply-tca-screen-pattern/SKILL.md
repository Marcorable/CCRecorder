---
name: apply-tca-screen-pattern
description: 기존 화면의 위치와 진입 경로를 유지한 채 TCA Screen.Root.Feature와 Action·Reducer·Dependency 구조를 적용한다. 화면 상태의 TCA 전환, Reducer 구성, child Feature 분리 요청에 사용한다. 파일 이동과 presentation 연결에는 단독으로 사용하지 않는다.
---

# TCA 화면 패턴 적용

`feature-composition`, `action-organization`, `reducer-decomposition`, `dependency`와 `effect-lifecycle` 규칙을 먼저 읽는다.

## 수행

1. 최상위 화면 상태와 사용자 시나리오를 `<Name>Screen.Root.Feature`가 소유하게 한다.
2. Action을 발생 주체와 역할에 따라 구성하고 Reducer를 정책 단위로 나눈다.
3. 독립 State와 Effect 생명주기가 있을 때만 child Feature로 분리한다.
4. 외부 동작은 `@Dependency` 계약으로 주입하고 Store 생성 지점에서 구현을 연결한다.
5. 장기 Effect의 시작, 취소와 자원 정리 경로를 대칭으로 만든다.
6. 대표 Action과 상태 전이를 `TestStore`로 검증한다.

## 제외

- 화면 파일을 다른 모듈로 이동하지 않는다.
- sheet·fullScreenCover·alert를 함께 재구성하지 않는다.
- View 계층이 깊다는 이유만으로 child Feature를 만들지 않는다.

## 결과와 검증

- View는 상태를 직접 바꾸지 않고 Action을 보낸다.
- Dependency 호출 경로와 Effect 종료 조건을 테스트한다.
