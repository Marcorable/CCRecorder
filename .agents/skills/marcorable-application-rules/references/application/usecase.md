
# Usecase 경계

Usecase는 여러 데이터 동작을 조합하거나 업무 정책과 원자성을 표현할 때 둔다. 단순 전달만 하는 Usecase는 만들지 않는다.

- 화면 이름이 아니라 수행하는 업무 동작으로 이름 짓는다
- 의존성은 명시적으로 주입하고 프로젝트가 이미 사용하는 묶음과 DI 방식을 따른다
- Repository의 기술 오류를 호출자가 이해할 수 있는 의미로 변환한다
- `throws`, typed throws와 `Result` 중 하나를 프로젝트와 호출 흐름에 맞게 일관되게 사용한다
- 화면 문구, loading, alert와 navigation 정책을 결정하지 않는다
- 하나로 성공하거나 실패해야 하는 동작은 Usecase와 Data 트랜잭션 경계를 함께 설계한다

점진적으로 교체할 때는 기존 Usecase와 새 Usecase가 같은 동작의 서로 다른 Source of Truth가 되지 않게 한다.
