---
paths:
  - "**/*.swift"
---

# TCA Child Feature 통신

부모 Feature는 Child를 조합하고 여러 Child가 함께 관여하는 시나리오를 조정한다. Child는 한 업무의 State, Action, Dependency Effect와 취소 범위를 소유한다.

- 부모가 Child의 Dependency 호출이나 응답을 대신 중계하지 않는다
- Child의 내부 Action은 Child에서 처리한다
- 부모에서 발생한 사건을 Child가 자신의 State 변경과 Effect로 해석해야 하면 `parent-child-event.md`에 따라 전달한다
- 부모가 알아야 하는 완료·선택 같은 사건만 `delegate`로 보낸다
- 부모는 Child의 구현 세부가 아니라 `delegate`가 표현한 의미에 반응한다

Child가 부모 Store 생성 시점의 Dependency를 상속하더라도 실제 동작의 소유권은 Child에 둔다.
