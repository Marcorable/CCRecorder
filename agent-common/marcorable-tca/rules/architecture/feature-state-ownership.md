---
paths:
  - "**/*.swift"
---

# TCA Feature 상태 소유권

수정 가능한 상태는 Feature 하나가 소유한다. 같은 Entity를 부모와 여러 Child State에 복제해 동기화하지 않는다.

1. Entity를 실제로 변경하는 Feature 하나를 소유자로 정한다.
2. 다른 Feature에는 ID나 필요한 불변 입력을 전달한다.
3. 여러 Feature가 항상 같은 Entity 전체를 변경해야 한다면 공통 부모가 소유한다.

Feature를 분리한 뒤에도 각 상태의 소유자와 변경 경로는 하나씩 남아야 한다.
