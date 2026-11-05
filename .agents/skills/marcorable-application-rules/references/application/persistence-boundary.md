
# 영속성 모델 경계

Domain 모델과 저장 소스의 모델을 분리한다. 저장 기술이 바뀌어도 Domain 계약과 소비 화면이 함께 바뀌지 않는 경계를 만든다.

## 저장 소스 전용 타입

- Repository 구현과 저장 소스 전용 타입은 Data가 소유한다
- Domain은 저장 프레임워크를 import하지 않는다
- Domain 입력에서 저장 모델로의 변환과 저장 모델에서 Domain Entity로의 복원은 Repository 구현이나 Data mapper가 담당한다
- initializer가 저장에 유효한 조합만 받게 해 잘못된 중간 상태를 만들지 않는다
- 저장 소스가 바뀌면 관련 Repository 구현과 저장 소스 전용 타입만 교체한다

저장 타입은 별도 타입으로 두거나 Domain Entity의 중첩 타입을 Data 모듈의 extension에서 구현할 수 있다. 기존 프로젝트의 이름과 접근 제어 관습을 우선한다.

## 트랜잭션 경계

- 여러 저장 작업이 함께 성공하거나 실패해야 하면 하나의 Aggregate Repository나 명시적인 Data 트랜잭션 경계가 소유한다
- Usecase가 여러 Repository를 순서대로 호출하는 것만으로 원자성이 보장된다고 가정하지 않는다
- 트랜잭션 단위와 Aggregate 경계가 다르면 어느 쪽이 업무 불변 조건을 소유하는지 먼저 정한다
