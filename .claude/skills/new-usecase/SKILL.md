---
name: new-usecase
description: 새 API 를 붙여 API → Repository → Usecase → DI 등록 → 화면 주입까지 Marco 의 레이어 패턴으로 만든다. "API 연동", "Usecase 추가", "Repository 만들어줘", 레거시 UseCase 대체 요청에 사용.
---

# Usecase 추가

QMarket #2741(`CertificationUsecase`), #2745(`NoticeRepository`)에서 반복한 흐름이다.
먼저 `.claude/rules/marcorable-swift/swift/usecase-repository.md` 를 읽는다. 파일 위치와 등록은 `.claude/rules/marcorable-swift/architecture/module-layout.md` 를 따른다. 실제 경로는 같은 종류의 기존 타입에서 찾는다.

## 0. 입력 확인

다음이 정해지지 않았으면 묻는다.

- 엔드포인트 — path, method, 요청 값, 응답 필드 (Swagger 링크가 있으면 받는다)
- 붙일 곳 — 기존 Usecase 에 메서드를 더할지, 새 Usecase 를 만들지
- 대체할 레거시 — 있으면 레거시 UseCase/Repository 이름

**계획(만들 파일, 고칠 등록 위치)을 먼저 보여주고 진행한다.**

## 1. API

1. `<Name>API` 타입 추가 — computed property 먼저, 저장 프로퍼티와 `init` 은 아래
2. API 목록에 등록

## 2. Repository

1. 프로토콜에 `func <동사>(...) async throws(DataError) -> T` 추가 (없으면 프로토콜 파일 생성)
2. Concrete 구현 — 응답 DTO 는 함수 안 지역 `struct Response`
3. 반환 타입이 화면 여러 곳에서 쓰이면 Entity 로 만든다. 한 곳이면 기본 타입(`Bool`, `Int`)으로 돌려준다
4. 새 Repository 면 Data 레이어 DI 컨테이너에 등록

## 3. Usecase

1. 프로토콜에 `async -> Result<T, DomainError>` 메서드 추가
2. Concrete 의 `Dependency` 에 Repository 추가, 메서드는 같은 Repository 를 쓰는 메서드 옆에
3. 레거시를 대체하면 프로토콜 메서드 위에 `// (Legacy) <원래 메서드> 대체`
4. 새 Usecase 면 Domain 레이어 DI 컨테이너에 등록. 의존성은 `resolver.resolve(<Repository>.self)!` 로 꺼낸다

## 4. 화면 주입

- ViewModel `Dependency` 에 Usecase 를 추가하고 화면 팩토리에서 `resolve`
- 호출은 `.claude/rules/marcorable-swift/swift/async-result.md` 순서를 따른다

## 5. 마무리

- 빌드
- 커밋은 `/commit` 으로 나눈다. type 은 동작이 바뀌는지로 고른다
  - 레거시에 있던 기능을 새 레이어로 다시 구성 → `refactor:` (동작 변화 없음)
  - 처음 생기는 API·기능, 그 화면 연동 → `feat:`

## 하지 않는 것

- 레거시 폴더에 새 Repository·UseCase 만들기
- Domain Entity 를 그대로 화면 표시 값으로 쓰기
- 이번 API 와 상관없는 레거시 정리
