---
name: separate-persistence-model
description: 저장 프레임워크에 결합된 모델을 Domain Entity와 Data Record로 분리하고 변환 경계를 만든다. SwiftData @Model 분리, DTO·저장 모델 격리, Domain의 저장 기술 의존 제거 요청에 사용한다. 전체 Aggregate의 소비 경로 전환에는 단독으로 사용하지 않는다.
---

# 영속성 모델 경계 분리

먼저 `../../rules/application/domain-modeling.md`와 `../../rules/application/persistence-boundary.md`를 읽는다. SwiftData를 사용하는 코드만 `../../rules/application/swiftdata-persistence.md`도 읽는다.

## 수행

1. 저장 모델이 맡고 있는 업무 의미와 저장 기술 책임을 구분한다.
2. 저장 기술과 무관한 값과 불변 조건을 Domain Entity로 옮긴다.
3. 저장 스키마와 framework 선언은 Data Record에 남긴다.
4. 생성 입력에서 Record로, Record에서 Entity로 가는 변환을 명시한다.
5. 기존 데이터 복원과 새 데이터 저장을 변환 테스트로 검증한다.

## 제외

- UI를 새 Entity로 한꺼번에 전환하지 않는다.
- 다른 Aggregate의 모델을 함께 이동하지 않는다.
- 저장 스키마 migration을 필요 이상으로 변경하지 않는다.

## 결과와 검증

- Domain이 저장 프레임워크를 import하지 않는다.
- 저장 Record가 Data 경계 밖으로 노출되지 않는다.
- round-trip 변환에서 업무 값이 보존된다.
