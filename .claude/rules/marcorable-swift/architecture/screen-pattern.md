---
paths:
  - "**/*.swift"
---

# 화면 구조 — Screen 네임스페이스

화면 하나는 `<Name>Screen` **네임스페이스 enum** 아래에 역할별 중첩 타입으로 나눈다. 파일도 타입마다 하나씩, 도트 이름으로 둔다.
SwiftUI 와 UIKit 이 같은 어휘(`Intent`, `Status`, `Model`, `ViewModel`, `Context`)를 쓴다. 차이는 View 쪽 바인딩뿐이다.

새 화면의 기본은 SwiftUI + `@Observable` 이다. UIKit 화면은 `ObservableObject` + `@Published` 를 ViewController 가 구독한다.

## 파일 구성

```
Search/
├── SearchScreen.swift                  # 네임스페이스 — Intent, Status, 상수
├── SearchScreen.Model.swift            # 비즈니스 로직 — Dependency, Result 반환
├── SearchScreen.ViewModel.swift        # 표시 상태 — reduce(by:)
├── SearchScreen.Context.swift          # 화면을 그리는 View
└── SearchScreen.ViewController.swift   # UIKit 만 — 바인딩, 화면 전환
```

## `<Name>Screen` — 네임스페이스

화면 안에서 같이 쓰는 타입과 상수만 둔다.

```swift

enum SearchScreen {

    enum Intent: Hashable {
        case input(String)
        case dismiss
        case select(_ rowAt: Int)
    }

    enum Status: Hashable, Error {
        case idle
        case alert(Alert)

        enum Alert: Hashable {
            case localized(_ message: String)
        }
    }

}

extension SearchScreen {

    static var debounce: Int { 600 }

}
```

- `Intent` — 사용자가 하려는 일. View 가 보내고 ViewModel 이 받는다
- `Status` — 실패와 취소를 **값**으로 나타낸다. `.idle` 은 아무것도 보여주지 않음, `.alert` 는 알릴 것

## `Model` — 비즈니스 로직

- 상태를 갖지 않는 `struct` 다. 의존성은 `Dependency` 로 받는다
- 메서드는 `async -> Result<T, Status>` 로 돌려준다. 에러를 화면이 다룰 `Status` 로 바꾸는 곳이 여기다
  - `CancellationError` → `.idle` (알리지 않는다)
  - 빈 입력 → `.idle`
  - 그 밖의 에러 → `.alert(...)`

```swift
extension SearchScreen.Model {
    typealias Status = SearchScreen.Status

    func search(by trimmed: String) async -> Result<[User], Status> {
        guard !trimmed.isEmpty else {
            return .failure(.idle)
        }
        do {
            let users = try await dependency.repository.searchUsers(by: trimmed)
            return .success(users)
        } catch is CancellationError {
            return .failure(.idle)
        } catch {
            return .failure(.alert(.localized(error.localizedDescription)))
        }
    }

}
```

## `ViewModel` — 표시 상태

- SwiftUI 는 `@MainActor @Observable final class`, UIKit 은 `final class: ObservableObject` + `@Published`
- 표시 상태는 모두 `private(set)` 이다. 바꾸는 길은 `reduce(by intent:)` 하나뿐이다
- `Model` 을 소유하고, 받은 `Result` 를 표시 상태로 옮긴다. `Status` 는 `private func update(by status:)` 에서 푼다
- 알럿은 문구가 아니라 **case** 로 갖는다 — `alert: Status.Alert?`. 문구는 `Context` 가 정한다 (`.claude/rules/marcorable-swift/architecture/section-subview.md`)
- 화면 전환은 직접 하지 않고 `route` 에 다음 화면을 넣는다

```swift
extension SearchScreen {

    @MainActor
    @Observable
    final class ViewModel {
        private(set) var input = ""
        private(set) var isLoading: Bool = false
        private(set) var rows: [Row.Model]?
        private(set) var alert: Status.Alert?
        private(set) var route: Screen?

        private let model: Model

        init(model: Model) {
            self.model = model
        }
    }

}

extension SearchScreen.ViewModel {
    typealias Intent = SearchScreen.Intent

    func reduce(by intent: Intent) {
        switch intent {
            case .input(let text):
                ...

            case .dismiss:
                ...

            case .select(let index):
                guard let row = rows?[safe: index] else {
                    return
                }
                self.route = .detail(row.name)
        }
    }

}

extension SearchScreen.ViewModel {
    typealias Status = SearchScreen.Status

    private func update(by status: Status) {
        self.isLoading = false
        self.alert = nil

        switch status {
            case .idle:
                break

            case .alert(let alert):
                self.alert = alert
        }
    }

}
```

### 화면 상태 정책

- 목록은 Optional 로 둔다. `nil` 은 아직 검색 전, `[]` 는 결과 없음
- 실패해도 이전 목록을 지우지 않는다
- 취소는 알리지 않는다
- 빈 입력은 목록을 `nil` 로 되돌린다

## `Context` — 화면을 그리는 View

- SwiftUI 는 `struct Context: View`. ViewModel 을 `@State` 로 소유하고, 입력은 `viewModel.reduce(by:)` 로만 보낸다
- ViewModel 이 고른 case 를 문구로 바꾸는 일은 `Context` extension 에서 한다

```swift
extension SearchScreen.Context {

    func message(_ alert: SearchScreen.Status.Alert) -> String {
        switch alert {
            case .localized(let message):
                message
        }
    }

}
```
- UIKit 은 `UIView` 하위 타입(예: `UITableView`). 입력은 `PassthroughSubject<Intent, Never>` 로 내보낸다
- `route` 가 바뀌면 화면 전환을 요청한다 — SwiftUI 는 `@Environment(\.mainStack)`, UIKit 은 ViewController 가 코디네이터에

## `ViewController` — UIKit 만

`Context` 를 `view` 로 쓰고, 바인딩을 셋으로 나눈다.

- `bindViewLifeCycle()` — 라이프사이클
- `bindInput()` — `context.intentPublisher` → `viewModel.reduce(by:)`
- `bindOutput()` — `viewModel.$상태` 를 구독해 화면 갱신, `$route` 로 화면 전환

## Mock

`Model`, `ViewModel` 에 `#if DEBUG` 로 `static var mock` 을 두고 프리뷰와 테스트에 쓴다. 의존성은 `Mock<프로토콜>` 로 채운다 (`.claude/rules/marcorable-swift/swift/testing.md`).

```swift
#if DEBUG
extension SearchScreen.ViewModel {

    static var mock: SearchScreen.ViewModel {
        .init(model: .mock)
    }

}
#endif
```
