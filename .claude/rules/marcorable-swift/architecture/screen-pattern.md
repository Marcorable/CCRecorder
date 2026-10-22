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
Search/                                 # 화면 폴더 위치는 ui-layout.md
├── SearchScreen.swift                  # 네임스페이스 — Intent, Status, 상수
├── SearchScreen.Model.swift            # 비즈니스 로직 — Dependency, Result 반환
├── SearchScreen.ViewModel.swift        # 표시 상태 — reduce(by:)
├── SearchScreen.Context.swift          # 화면을 그리는 View
└── SearchScreen.ViewController.swift   # UIKit 만 — 바인딩, 화면 전환
```

로직이 아직 없는 화면은 네임스페이스와 `Context` 만으로 시작해도 된다. `Model`, `ViewModel` 은 필요해질 때 더한다.

```swift
enum ConversationListScreen {}

extension ConversationListScreen {

    struct Context: View { ... }

}
```

화면 단위 타입에 `View` 접미사를 붙이지 않는다. 폴더 배치와 컴포넌트와의 경계는 `agent-common/marcorable-swift/rules/architecture/ui-layout.md` 를 따른다.

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
- 표시 상태는 기본적으로 `private(set)` 이고 바꾸는 길은 `reduce(by intent:)` 하나뿐이다
- SwiftUI 가 sheet, fullScreenCover 같은 단순 표시 상태를 직접 쓰는 양방향 바인딩은 예외로 internal setter 를 허용한다. 바인딩의 쓰기 값을 전달하기만 하는 dismiss Intent 는 만들지 않는다
- 바인딩 변경에 검증, 부수 효과 또는 비즈니스 상태 변경이 필요하면 internal setter 를 열지 않고 Intent 를 사용한다
- item 기반 presentation은 `Status` 안에 modifier 종류별 enum으로 나눈다 — `Status.Sheet`, `Status.FullScreenCover`. 다른 presentation 종류가 필요하면 같은 방식으로 중첩 enum을 추가한다. 실패를 다루는 화면에 이미 `.idle`, `.alert`가 있으면 그대로 유지한다
- 각 presentation enum에서 값 전체가 식별자라면 프로젝트의 `IdentifiableFeature`(또는 같은 역할의 타입)를 사용한다. 그런 타입이 없거나 일부 값만 식별자라면 직접 `id`를 구현한다 (`agent-common/marcorable-swift/rules/architecture/ui-layout.md`)
- `Model` 을 소유하고, 받은 `Result` 를 표시 상태로 옮긴다. `Status` 는 `private func update(by status:)` 에서 푼다
- 알럿은 문구가 아니라 **case** 로 갖는다 — `alert: Status.Alert?`. 문구는 `Context` 가 정한다 (`agent-common/marcorable-swift/rules/architecture/section-subview.md`)
- 네비게이션 스택(push)은 직접 하지 않고 `route` 에 다음 화면을 넣는다. sheet · fullScreenCover 는 아래 Presentation 상태를 쓴다

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

### Presentation 상태

`sheet(item:)`, `fullScreenCover(item:)`처럼 item으로 표시하는 화면은 presentation 종류마다 중첩 enum과 Optional 상태를 하나씩 둔다. case가 늘어나도 Bool 상태를 추가하지 않고 해당 enum에 목적지를 추가한다.
이 enum은 화면 상태의 네임스페이스인 `Status` 의 중첩 타입이다. 실패를 다루는 화면은 기존 `.idle`, `.alert`와 `Error` 채택을 유지한다. presentation만 있는 화면은 쓰지 않는 실패 case나 `Error` 채택을 추가하지 않는다.

```swift
extension SettingScreen {

    enum Status: Hashable {
        enum Sheet: IdentifiableFeature {
            case information
        }

        enum FullScreenCover: IdentifiableFeature {
            case tutorial
        }
    }

}

extension SettingScreen {

    @MainActor
    @Observable
    final class ViewModel {
        var presentedSheet: Status.Sheet?
        var presentedFullScreenCover: Status.FullScreenCover?
    }

}
```

Context 는 각 상태를 대응하는 modifier에 직접 바인딩하고 case에 따라 화면을 고른다.

```swift
.sheet(item: $viewModel.presentedSheet) {
    switch $0 {
        case .information:
            InformationScreen.Context()
    }
}
.fullScreenCover(item: $viewModel.presentedFullScreenCover) {
    switch $0 {
        case .tutorial:
            OnboardScreen.Context()
    }
}
```

### 화면 상태 정책

- 목록은 Optional 로 둔다. `nil` 은 아직 검색 전, `[]` 는 결과 없음
- 실패해도 이전 목록을 지우지 않는다
- 취소는 알리지 않는다
- 빈 입력은 목록을 `nil` 로 되돌린다

## `Context` — 화면을 그리는 View

- SwiftUI 는 `struct Context: View`. ViewModel 을 `@State` 로 소유하고, 입력은 `viewModel.reduce(by:)` 로 보낸다. 직접 바인딩을 허용한 단순 표시 상태는 `$viewModel.<상태>`로 연결한다
- 화면 전용 하위 View 에 화면 단위 상태와 Intent 가 필요하면 Context 에서 `.environment(viewModel)`로 주입한다. 하위 View 의 표시 데이터는 하위 ViewModel 로 명시적으로 전달한다 (`agent-common/marcorable-swift/rules/architecture/section-subview.md`)
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

`Model`, `ViewModel` 에 `#if DEBUG` 로 `static var mock` 을 두고 프리뷰와 테스트에 쓴다. 의존성은 `Mock<프로토콜>` 로 채운다 (`agent-common/marcorable-swift/rules/swift/testing.md`).

```swift
#if DEBUG
extension SearchScreen.ViewModel {

    static var mock: SearchScreen.ViewModel {
        .init(model: .mock)
    }

}
#endif
```
