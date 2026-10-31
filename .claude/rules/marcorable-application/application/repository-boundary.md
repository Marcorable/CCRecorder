---
paths:
  - "**/*Repository*.swift"
  - "**/Domain/**/*.swift"
  - "**/Data/**/*.swift"
---

# Repository 계약 경계

- Repository 계약은 Domain이 소유하고 구현은 Data가 소유한다
- 입출력에는 Domain 타입, 식별자와 경계가 소유한 오류만 사용한다
- DTO, 저장 Record, 네트워크·저장 프레임워크 타입을 계약에 노출하지 않는다
- Repository는 Entity마다 만들지 않고 독립적으로 조회·저장되는 Aggregate Root를 기준으로 만든다
- Aggregate 내부 타입은 상위 Aggregate의 Repository를 통해 다룬다
- CRUD 모양을 먼저 만들지 말고 호출자가 필요로 하는 업무 동작으로 계약을 표현한다
- 반환값은 다음 흐름에 필요한 최소 의미로 정한다. 식별자만 필요하면 Entity 전체를 반환하지 않는다

Repository가 단순 전달 계층에 그치고 교체·테스트·업무 경계를 만들지 못한다면 새 추상화를 추가하지 않는다.
