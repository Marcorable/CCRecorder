---
name: apply-tca-screen-pattern
description: 기존 화면의 위치와 진입 경로를 유지한 채 TCA Screen.Root.Feature와 Action·Reducer·Dependency 구조를 적용한다. 화면 상태의 TCA 전환, Reducer 구성, child Feature 분리 요청에 사용한다. 파일 이동과 presentation 연결에는 단독으로 사용하지 않는다.
---

# TCA 화면 패턴 적용

`feature-composition`, `action-organization`, `reducer-decomposition`, `dependency`와 `effect-lifecycle` 규칙을 먼저 읽는다.

## 수행

1. `<Name>Screen.Root.Feature`에는 Child 구성, presentation, navigation, 화면 진입·종료와 여러 Child를 잇는 상위 시나리오를 둔다.
2. 하위 영역의 주 업무가 자체 State·Action·Dependency Effect·취소 범위를 가지면 Child Feature로 분리한다.
3. Root가 Child의 Dependency 호출을 대신 전달하지 않게 하고, 의미 있는 결과만 `delegate`로 받는다.
4. View 계층과 Feature 경계를 별도로 판단한다. 여러 View가 같은 업무 상태를 사용하면 하나의 Child Store를 각각 전달한다.
5. Entity를 Root와 Child에 복제하지 않는다. Child에는 ID나 불변 입력을 전달하고, 공유 Source of Truth가 필요하면 소유 Feature를 하나로 정한다.
6. Action을 발생 주체와 역할에 따라 구성하고 Reducer를 정책 단위로 나눈다.
7. 외부 동작은 `@Dependency` 계약으로 주입하고 Store 생성 지점에서 구현을 연결한다.
8. 장기 Effect의 시작, 취소와 자원 정리 경로를 대칭으로 만든다.
9. Root 조정 흐름과 Child의 대표 업무 상태 전이를 각각 `TestStore`로 검증한다.

## 제외

- 화면 파일을 다른 모듈로 이동하지 않는다.
- sheet·fullScreenCover·alert를 함께 재구성하지 않는다.
- View 계층이 깊다는 이유만으로 child Feature를 만들지 않는다.

## 결과와 검증

- View는 상태를 직접 바꾸지 않고 Action을 보낸다.
- Dependency 호출 경로와 Effect 종료 조건을 테스트한다.
