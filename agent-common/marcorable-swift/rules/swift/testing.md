---
paths:
  - "**/*.swift"
---

# 테스트와 Mock

## Mock

진짜 구현 대신 넣는 가짜 구현은 `Mock<프로토콜명>` 으로 짓고, **프로토콜을 정의한 파일 안**에 `#if DEBUG` 로 감싸 둔다.
테스트와 프리뷰가 같은 Mock 을 쓴다.

- 돌려줄 값은 프로퍼티로 두고 기본값으로 샘플을 넣는다
- 실패와 지연을 시험할 수 있게 `error`, `delay` 를 바꿔 넣을 수 있게 한다
- Entity 는 샘플 값으로 `static var dummy` 를 둔다

```swift
public protocol UserRepository {
    func searchUsers(by query: String) async throws -> [User]
}

#if DEBUG
public final class MockUserRepository: UserRepository, @unchecked Sendable {
    public var users: [User]
    public var error: Error?
    public var delay: Duration

    public init(
        users: [User] = [.dummy],
        error: Error? = nil,
        delay: Duration = .zero
    ) {
        self.users = users
        self.error = error
        self.delay = delay
    }

    public func searchUsers(by query: String) async throws -> [User] {
        try await Task.sleep(for: delay)
        if let error {
            throw error
        }
        return users
    }
}
#endif
```

`error` 를 넣으면 실패를, `delay` 를 넣으면 느린 응답을 서버 없이 만든다. 기본값(`nil`, `.zero`)이면 바로 샘플을 돌려준다.

## 원칙

- **테스트는 문서다.** 테스트 이름만 읽어도 그 기능이 무엇을 하는지 알 수 있게 쓴다
- **성공과 실패는 함수의 목적으로 정한다.** 목적을 이룬 경우와 이루지 못한 경우를 짝으로 시험한다
  - `popFirst()` 가 빈 리스트에서 `nil` 을 돌려주는 것은 오류가 아니라 "pop 하지 못함" 이라는 정해진 결과다
  - 이름에 "성공케이스" / "실패케이스" 를 붙이지 않고 **기대하는 결과**를 적는다
- **테스트하기 어려우면 설계를 본다.** 함수가 두 가지 일을 하거나 이름이 목적을 말하지 않는다는 신호다
  - 실패는 `throw` 나 `Result`, Optional 반환으로 드러낸다. `fatalError` 로 끝내면 실패 경로를 시험할 수 없다

## 테스트 파일

- Swift Testing 으로 쓴다 — `import Testing`
- 파일은 `<타입>.<주제>Tests.swift`, 타입은 `<타입><주제>Tests` — `SearchScreen.FailurePolicyTests.swift` / `SearchScreenFailurePolicyTests`
- `@Suite("한국어 주제")` 를 붙인 **struct** 로 만든다. 테스트마다 새 인스턴스가 생기므로 준비는 `init` 에서 한다
- 테스트 함수는 별도 extension 에 둔다
- `@MainActor` 타입을 시험하면 Suite 에 `@MainActor` 를 붙인다

```swift

import Testing

import SharedKit

@testable import SwiftUIObservable

@Suite("SearchScreen 실패 정책")
@MainActor
struct SearchScreenFailurePolicyTests {
    private let repository = MockUserRepository()
    private let viewModel: SearchScreen.ViewModel

    init() {
        viewModel = .init(model: .init(dependency: .init(repository: repository)))
    }
}

extension SearchScreenFailurePolicyTests {

    @Test("검색이 실패하면 이전 결과를 유지하고 알럿을 띄운다")
    func failureKeepsPreviousRows() async {
        // given
        repository.error = SharedKitError.invalidResponse

        // when
        await viewModel.search()

        // then
        #expect(viewModel.presentedAlertString != nil)
    }

}
```

## 테스트 함수

- `@Test("...")` 에 **기대하는 결과를 한국어 문장**으로 적는다 — "빈 리스트에서 popFirst 하면 nil 을 돌려준다"
- 함수 이름은 영어로 짧게, `test` 접두사 없이 쓴다 — `popFirstOnEmptyReturnsNil`
- 같은 정책을 시험하면 대상이 달라도 같은 함수 이름을 쓴다
- 본문은 `// given`, `// when`, `// then` 주석으로 나눈다. 준비할 것이 없으면 `// given` 은 뺀다
- 확인은 `#expect`, 꼭 있어야 하는 값은 `try #require` 로 꺼낸다. 테스트 안에서 `!` 로 강제 언래핑하지 않는다
- 입력만 다른 경우가 여럿이면 `@Test(arguments:)` 로 묶는다

```swift
// ✅
@Test("빈 리스트에서 popFirst 하면 nil 을 돌려준다")
func popFirstOnEmptyReturnsNil() {
    // given
    var list = LinkedList<Int>()

    // when
    let value = list.popFirst()

    // then
    #expect(value == nil)
}

@Test("값이 있으면 popFirst 가 첫 값을 돌려준다")
func popFirstReturnsHead() throws {
    // given
    var list = LinkedList<Int>()
    list.push(1)

    // when
    let value = try #require(list.popFirst())

    // then
    #expect(value == 1)
}

@Test(
    "재고가 부족하면 주스를 만들지 못한다",
    arguments: [Juice.strawberry, .banana]
)
func makeJuiceFailsWhenOutOfStock(juice: Juice) {
    // given
    let maker = JuiceMaker(store: .empty)

    // when
    let result = maker.make(juice)

    // then
    #expect(result == .failure(.outOfStock))
}

// ❌ 두 경우 모두 같은 이름, 결과가 이름에 없음, 강제 언래핑
func test_실패케이스_popFirst를_호출하면_head노드를_pop한다() { ... }
let value = list.popFirst()!
```
