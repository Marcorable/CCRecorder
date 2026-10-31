---
name: connect-tca-presentation
description: TCA 부모 Feature에 sheet·fullScreenCover·alert 상태와 child Feature를 연결하고 dismiss 후처리를 구현한다. @Presents 전환, PresentationAction 연결, dismiss 후 reload 요청에 사용한다. 화면 전체 TCA 마이그레이션에는 단독으로 사용하지 않는다.
---

# TCA presentation 연결

먼저 `../../rules/architecture/presentation.md`와 `../../rules/architecture/dependency.md`를 읽는다.

## 입력

- presentation을 띄우는 부모 Feature
- destination 또는 child Feature
- dismiss 뒤 부모가 처리할 갱신과 영속 상태

## 수행

1. presentation 상태를 실제로 소유해야 하는 가장 가까운 부모 Feature를 정한다.
2. `@Presents` State와 `PresentationAction`을 추가하고 reducer에 child를 조합한다.
3. View의 시스템 presentation API를 scoped Store에 연결한다.
4. 자식은 dismiss 의도만 보내고 reload·저장 같은 후처리는 부모가 수행하게 한다.
5. child Dependency가 부모 Store 생성 지점에서 준비됐는지 확인한다.

## 제외

- 단순 dismiss를 위해 별도 Bool과 수동 Binding을 중복해서 만들지 않는다.
- 전역 presentation이 아닌 화면 전용 상태를 App에 올리지 않는다.
- 부모와 자식의 나머지 상태 구조를 함께 바꾸지 않는다.

## 결과와 검증

- 사용자 Action이 presentation 상태를 생성한다.
- dismiss가 child 상태를 제거하고 필요한 부모 후처리를 실행한다.
- 실제 presentation 진입과 종료를 테스트와 실행 환경에서 확인한다.
