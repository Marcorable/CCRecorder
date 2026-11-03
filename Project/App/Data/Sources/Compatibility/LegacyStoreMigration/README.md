# Legacy Store Migration

이 디렉터리는 현재 저장 구조가 아니라 이전 앱 버전과의 호환 계층이다.

## 지원 범위

- App Store에서 v1 또는 v2를 건너뛰고 현재 버전으로 바로 업데이트하는 경로를 지원한다.
- v1 `CasualConversation.sqlite`와 `Documents/Records`, 배포된 v2 `default.store`를 읽는다.
- 현재 Source of Truth는 기존 `Conversation.Record`, `Note.Record`, `Party.Record`와 각 Repository다.
- 원본 저장소는 복사본으로 읽고, v1 녹음도 현재 디렉터리에 복사하므로 원본을 변경하거나 삭제하지 않는다.

## 진입점

- 앱에서는 `DataFactory.preparePersistence()`만 호출한다.
- 이 디렉터리의 타입은 Data 모듈 내부 구현이며 일반 기능 코드에서 직접 의존하지 않는다.
- 회귀 테스트는 `Data/Tests/Compatibility/LegacyStoreMigration`에 함께 격리한다.

## 제거 기준

App Store 업데이트는 중간 버전을 건너뛸 수 있으므로 최근 실행 비율이나 최신 버전 보급률만으로 제거하지 않는다. 제품 정책상 v1·v2에서의 직접 업데이트 데이터 호환을 종료하기로 결정한 뒤, 이 디렉터리와 전용 fixture 테스트 및 `CasualConversation.xcdatamodeld`를 함께 제거한다.
