---
paths:
  - "**/*.swift"
---

# AppStorage 키 adapter

SwiftUI target이 `@AppStorage`를 사용할 때 `marcorable-application`의 `preference-key.md`에 정의한 키 타입을 받는 initializer를 둔다. 저장 키의 수명과 마이그레이션은 그 규칙이 소유하며, 이 규칙은 SwiftUI 바인딩 문법만 다룬다.

- 호출부에서는 문자열이나 `.rawValue` 대신 `.displayMode`처럼 키 case를 전달한다
- initializer는 실제로 쓰는 값 타입만 만든다. 새 값 타입이 필요해질 때 해당 overload를 추가한다

```swift
// ✅
extension AppStorage {

    init(
        wrappedValue: Value,
        _ key: PreferenceKey,
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
        _ key: PreferenceKey,
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
        _ key: PreferenceKey,
        store: UserDefaults? = nil
    ) where Value: RawRepresentable, Value.RawValue == Int {
        self.init(
            wrappedValue: wrappedValue,
            key.rawValue,
            store: store
        )
    }

}

@AppStorage(.isFirstLaunched) private var isFirstLaunched = false
@AppStorage(.displayMode) private var displayMode: DisplayMode = .system

// ❌
@AppStorage("isFirstLaunched") private var isFirstLaunched = false
@AppStorage(PreferenceKey.isFirstLaunched.rawValue) private var isFirstLaunched = false
```
