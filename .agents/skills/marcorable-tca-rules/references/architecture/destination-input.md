
# TCA Destination 진입값

Navigation route와 presentation state의 진입값은 화면이 요구하는 데이터 시점을 기준으로 정한다.

- 전달 시점의 스냅샷이 목적이면 Entity를 값으로 전달할 수 있다
- 진입 시점의 최신 원본이 필요하면 ID를 전달하고 Destination이 조회한다
- 실제 `Set` 원소나 Dictionary key로 쓰지 않는 Entity에 navigation만을 위한 `Hashable`을 추가하지 않는다
- State 비교만 필요하면 `Equatable`로 유지한다

ID 전환 자체를 목표로 삼지 않고 스냅샷과 최신 원본 중 어떤 의미가 필요한지 먼저 정한다.
