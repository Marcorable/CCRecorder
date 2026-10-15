
import Foundation

extension SettingScreen {

    struct Model {
        private let dependency: Dependency

        init(dependency: Dependency) {
            self.dependency = dependency
        }
    }

}

extension SettingScreen.Model {

    struct Dependency {
        let bundle: Bundle
    }

}

extension SettingScreen.Model {

    var appVersion: String? {
        dependency.bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

}

#if DEBUG
extension SettingScreen.Model {

    static var mock: Self {
        .init(dependency: .init(bundle: .main))
    }

}
#endif
