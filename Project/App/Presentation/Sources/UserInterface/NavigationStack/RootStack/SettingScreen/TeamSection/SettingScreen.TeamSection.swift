
import SwiftUI

extension SettingScreen {

    struct TeamSection: View {
        var body: some View {
            Section("Team Marcoda") {
                ForEach(Row.Content.all, id: \.self) {
                    Row(content: $0)
                }
            }
        }
    }

}

extension SettingScreen.TeamSection {

    struct Row: View {
        let content: Content

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(content.name)
                    .font(.headline)
                Text(content.role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(content.links, id: \.self) {
                        Link($0.title, destination: $0.url)
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }

}

extension SettingScreen.TeamSection.Row {

    struct Content: Hashable {
        let name: String
        let role: String
        let links: [Link]

        struct Link: Hashable {
            let title: String
            let url: URL
        }

        static let all: [Self] = [
            .init(
                name: "Marco",
                role: "Team Leader · iOS Development",
                links: [
                    .init(
                        title: "GitHub",
                        url: URL(string: "https://github.com/Marcorable")!
                    ),
                ]
            ),
            .init(
                name: "Coda",
                role: "Project Management",
                links: [
                    .init(
                        title: "GitHub",
                        url: URL(string: "https://github.com/dacodaco")!
                    ),
                ]
            ),
        ]
    }

}

#Preview {
    Form {
        SettingScreen.TeamSection()
    }
}
