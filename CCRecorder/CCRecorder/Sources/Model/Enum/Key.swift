
import SwiftUI
import Foundation

enum Key: String {
    // MARK: 앱 상태
    case isFirstLaunched
    case isLegacyStoreMigrated

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
