---
paths:
  - "**/*App.swift"
  - "**/Data/**/*.swift"
  - "**/*Record*.swift"
---

# SwiftData 저장 경계

SwiftData를 사용하는 범위에서만 이 규칙을 적용한다. 공통 Domain·Data 경계는 `persistence-boundary.md`를 따른다.

## 저장 모델

- `@Model` 타입과 SwiftData extension은 Data가 소유한다
- Domain Entity가 `@Model`, `ModelContext`나 `PersistentIdentifier`를 알지 않게 한다
- Record와 Domain Entity 사이의 양방향 변환을 명시하고 기존 데이터 복원을 검증한다

## 인프라와 격리

- Composition Root가 영구·메모리 저장 환경과 `ModelContainer` 생성 시점을 결정한다
- Data Factory는 `ModelContainer`를 모듈 내부에 보관하고 Domain의 Repository 계약을 반환할 수 있다
- Repository가 Context를 전담하면 `@ModelActor`와 주입받은 `ModelContainer`로 자신의 실행 경계를 소유한다
- 호출부는 Repository의 async API를 호출하고 UI 상태만 MainActor 경계에서 반영한다
- View가 `@Query`나 `modelContext`를 직접 사용하지 않으면 Presentation에 `modelContainer`를 노출하지 않는다

## 트랜잭션

같은 `ModelContainer`를 사용해도 서로 다른 `ModelContext`의 작업은 하나의 트랜잭션이 아니다. 함께 성공하거나 실패해야 하는 저장은 하나의 Context를 소유한 Data 경계에서 처리한다.
