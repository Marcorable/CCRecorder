
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

    var informationSection: SettingScreen.InformationSection.Model {
        .init(
            appVersion: appVersion,
            instagramURL: URL(string: "https://www.instagram.com/casualconversation_ccrecorder/")!,
            mailURL: URL(string: "mailto:pse.applications@gmail.com")!
        )
    }

    var teamSection: SettingScreen.TeamSection.Model {
        .init(
            rows: [
                .init(
                    name: "Marco",
                    role: "Team Leader · iOS Development",
                    links: [
                        .init(title: "GitHub", url: URL(string: "https://github.com/Marcorable")!),
                    ]
                ),
                .init(
                    name: "Coda",
                    role: "Project Management",
                    links: [
                        .init(title: "GitHub", url: URL(string: "https://github.com/dacodaco")!),
                    ]
                ),
            ]
        )
    }

}

#if DEBUG
extension SettingScreen.Model {

    static var mock: Self {
        .init(dependency: .init(bundle: .main))
    }

}
#endif
