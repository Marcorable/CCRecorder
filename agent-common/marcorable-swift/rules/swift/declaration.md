---
paths:
  - "**/*.swift"
---

# 선언과 이름

## 타입

- class 는 기본으로 `final class` 로 쓴다
- 접근 수준을 의도대로 적는다. 밖에서 쓸 일이 없으면 `private`, 밖에서 읽기만 하면 `private(set)`
- `@Observable` 타입이 가진 의존성은 `@ObservationIgnored` 로 관찰에서 뺀다

```swift
@Observable
@MainActor
final class Model {
    @ObservationIgnored private let dependency: Dependency
    private(set) var items: [Item] = []
}
```

## `.init` 축약

타입이 문맥상 분명하면 `.init(...)` 으로 줄인다.

```swift
// ✅
viewModel.model = .init(
    representative: info.representative,
    businessRegistrationNumber: info.number
)

// ❌
viewModel.model = BusinessInfoSection.Model(...)
```

## 인자 레이블

호출부가 구처럼 읽히게 레이블을 짓는다.

```swift
func reject(refund id: Int, reason: String)
func approved(refund: Refund) -> Bool

reject(refund: 42, reason: "재고 없음")
```

## Bool 이름

- 할 수 있는지: `isAbleTo~` — `isAbleToReject`, `isAbleToSubmit`
- 필요한지: `~Needs` — `authorizationNeeds`
- 파생 상태는 ViewModel extension 의 computed property 로 둔다

## 저장 키

`UserDefaults` · `@AppStorage` 키는 `enum Key: String` 하나에 case 로 모은다. 문자열을 직접 쓰지 않는다.
case 이름이 그대로 저장 키가 되므로 **이미 배포한 키의 case 이름은 바꾸지 않는다.** 바꿔야 하면 기존 값을 옮기는 마이그레이션을 함께 쓴다.

- case 는 용도별로 묶고, 묶음 사이에 빈 줄과 `// MARK: <용도>` 를 둔다
- 같은 파일 하단에 `Key` 를 받는 `AppStorage` · `UserDefaults` 오버로드를 두고, 호출부에서는 `.rawValue` 없이 `.displayMode` 처럼 쓴다
- 오버로드는 **실제로 쓰는 값 타입만** 만든다. 새 값 타입이 필요해지면 그때 추가한다

```swift
// ✅
enum Key: String {
    // MARK: 앱 상태
    case isFirstLaunched

    // MARK: 화면 설정
    case displayMode
    case isIdleTimerDisabled

    // MARK: 재생 설정
    case skipInterval
}

extension AppStorage {

    init(
        wrappedValue: Value,
        _ key: Key,
        store: UserDefaults? = nil
    ) where Value == Bool {
        self.init(
            wrappedValue: wrappedValue,
            key.rawValue,
            store: store
        )
    }

    init(
        wrappedValue: Value,
        _ key: Key,
        store: UserDefaults? = nil
    ) where Value: RawRepresentable, Value.RawValue == String {
        self.init(
            wrappedValue: wrappedValue,
            key.rawValue,
            store: store
        )
    }

    init(
        wrappedValue: Value,
        _ key: Key,
        store: UserDefaults? = nil
    ) where Value: RawRepresentable, Value.RawValue == Int {
        self.init(
            wrappedValue: wrappedValue,
            key.rawValue,
            store: store
        )
    }

}

extension UserDefaults {

    func bool(forKey key: Key) -> Bool {
        bool(forKey: key.rawValue)
    }

    func set(
        _ value: Bool,
        forKey key: Key
    ) {
        set(
            value,
            forKey: key.rawValue
        )
    }

    func removeObject(forKey key: Key) {
        removeObject(forKey: key.rawValue)
    }

}

@AppStorage(.isFirstLaunched) private var isFirstLaunched = false
@AppStorage(.displayMode) private var displayMode: DisplayMode = .system
@AppStorage(.skipInterval) private var skipInterval: SkipInterval = .five
userDefaults.bool(forKey: .isFirstLaunched)

// ❌
@AppStorage("isFirstLaunched") private var isFirstLaunched = false
@AppStorage(Key.isFirstLaunched.rawValue) private var isFirstLaunched = false

extension String {
    enum Key {
        static var displayMode: String { "\(#function)" }
    }
}
```
