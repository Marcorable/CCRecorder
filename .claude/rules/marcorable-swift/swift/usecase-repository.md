---
paths:
  - "**/*Usecase*.swift"
  - "**/*Repository*.swift"
  - "**/*API.swift"
  - "**/*Factory*.swift"
---

# Usecase · Repository · API 작성

의존 방향은 `Presentation → Usecase → Repository(프로토콜) ← Repository 구현 → API` 다.
Domain 은 Repository **프로토콜**만 가지고, 구현은 Data 레이어에 둔다.

## 이름

- 프로토콜은 역할 이름 그대로, 구현은 `Concrete` 접미사 — `MyPageUsecase` / `MyPageUsecaseConcrete`, `NoticeRepository` / `NoticeRepositoryConcrete`
- API 는 엔드포인트 하나당 타입 하나, `API` 접미사 — `NewNoticeExistAPI`

## 시그니처

| 레이어 | 형태 |
|---|---|
| Repository | `async throws(DataError) -> T` |
| Usecase | `async -> Result<T, DomainError>` — throw 하지 않고 Result 로 돌려준다 |

## 에러 변환

각 레이어가 아래 레이어 에러를 한 번씩 감싼다. 모르는 에러는 `.system` 이다.

```swift
// Repository
} catch let error as APIError {
    throw .api(error)
} catch {
    throw .system(error)
}

// Usecase — Repository 가 typed throws 면 catch 하나로 충분하다
do {
    let hasNew = try await dependency.noticeRepository.hasNew(martId: martId)
    return .success(hasNew)
} catch {
    return .failure(.data(error))
}
```

typed throws 가 아닌 Repository 를 부를 때만 `catch let error as DataError` 와 `catch` 를 나눈다.

## Concrete 구성

의존성은 **하나뿐이어도** `Dependency` 중첩 struct 로 묶어 `init(dependency:)` 로 받는다.

```swift
final class MyPageUsecaseConcrete {
    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

extension MyPageUsecaseConcrete {

    struct Dependency {
        let userRepository: UserRepository
        let noticeRepository: NoticeRepository
    }

}

extension MyPageUsecaseConcrete: MyPageUsecase {

    func userInfo(martId: Int?) async -> Result<UserInfo, DomainError> { ... }

    func hasNewNotice(martId: Int) async -> Result<Bool, DomainError> { ... }

}
```

- 프로토콜 채택은 별도 extension 에 둔다
- Usecase 메서드는 **사용하는 Repository 별로 모아 둔다.** `// MARK:` 주석은 달지 않는다

## 응답 DTO

응답 모델이 그 함수에서만 쓰이면 함수 안에 지역 struct 로 둔다.

```swift
func hasNew(martId: Int) async throws(DataError) -> Bool {

    struct Response: Decodable {
        let hasNewNotice: Bool
    }

    do {
        let data = try await APIFactory.make(api: .notice(.hasNew(martId: martId)))
            .request()
        let response = try JSONDecoder().decode(
            Response.self,
            from: data
        )
        return response.hasNewNotice
    } catch let error as APIError {
        throw .api(error)
    } catch {
        throw .system(error)
    }
}
```

## API 타입

`path` / `method` / `task` 같은 요구사항은 computed property 로 먼저 쓰고, 저장 프로퍼티와 `init` 은 그 아래에 둔다.
외부 모듈 의존은 access-level import 로 숨긴다 — `internal import Moya`.

타입 위 문서 주석에 Swagger 링크를 단다.

```swift
/// - Tip: [환불 승인](https://.../swagger-ui/#/refund/approve)
struct RefundApprovalAPI: PartnersAPI {
```

## 레거시 대체

레거시 UseCase/Repository 를 대체하는 메서드에는 무엇을 대체하는지 주석으로 남긴다.
중복이 남으면 `// FIXME:` 로 표시한다.

```swift
// (Legacy) AccountIntegrationStateUseCaseProtocol.fetchIntegrationState() 대체
func integrationResult() async -> Result<IntegrationResult, DomainError>
```
