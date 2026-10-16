
import Foundation

enum SettingScreen {

    enum Intent: Hashable {
        case presentTutorial
        case dismissTutorial
    }

    struct TeamMate: Hashable {
        let name: String
        let role: String
        let links: [ExternalLink]
    }

    struct ExternalLink: Hashable {
        let title: String
        let url: URL
    }

}

extension SettingScreen {

    static var instagramURL: URL { URL(string: "https://www.instagram.com/casualconversation_ccrecorder/")! }
    static var mailURL: URL { URL(string: "mailto:pse.applications@gmail.com")! }

    static var teamMates: [TeamMate] {
        [
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
    }

}
