
# 애플리케이션 책임 배치

새 코드는 역할에 맞는 레이어가 소유한다. 폴더와 모듈 이름보다 실제 책임과 의존 방향을 우선한다.

## 어디에 두나

| 무엇 | 레이어 |
|---|---|
| API 엔드포인트·DTO | Data 또는 별도 API client 모듈 |
| Repository 계약 | Domain |
| Repository 구현 | Data |
| Usecase | Domain 또는 Application |
| Entity | Domain |
| 공용 UI · Manager | Presentation |

## 등록

새 API부터 소비 지점까지 이어지는 요청이면 실제로 추가한 경계의 등록 위치를 함께 고친다. 등록 위치는 프로젝트마다 다르므로 같은 종류의 기존 타입이 등록된 곳을 찾아 따른다.

## 레이어 모듈이 없는 앱

모듈을 나누지 않은 단일 타깃 앱도 Domain Entity와 외부 기술 전용 타입의 역할과 의존 방향을 구분한다.

- Domain Entity에는 `@Model`, DTO 코딩 키처럼 외부 기술에 필요한 선언을 넣지 않는다
- 저장 Record와 DTO는 Data에서 Domain Entity로 변환한 뒤 화면과 Usecase에 전달한다
- 여러 화면이 함께 쓰는 Domain 열거형은 관련 Entity가 소유하고, 한 화면에서만 쓰는 열거형은 그 화면에 중첩한다
- 새 최상위 폴더를 만들기 전에 같은 책임의 기존 타입이 어디에 있는지 확인한다
