
import SwiftUI

extension SettingScreen {

    struct TeamSection: View {
        let viewModel: ViewModel

        var body: some View {
            Section("Team Marcoda") {
                ForEach(viewModel.rows, id: \.self) {
                    Row(viewModel: $0)
                }
            }
        }
    }

}

extension SettingScreen.TeamSection {

    struct Model {
        let rows: [Row.Model]
    }

    struct ViewModel {
        let model: Model
    }

}

extension SettingScreen.TeamSection.ViewModel {

    var rows: [SettingScreen.TeamSection.Row.ViewModel] {
        model.rows.map {
            .init(model: $0)
        }
    }

}

extension SettingScreen.TeamSection {

    struct Row: View {
        let viewModel: ViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name)
                    .font(.headline)
                Text(viewModel.role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(viewModel.links, id: \.self) {
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

    struct Model: Hashable {
        let name: String
        let role: String
        let links: [ExternalLink]

        struct ExternalLink: Hashable {
            let title: String
            let url: URL
        }
    }

    struct ViewModel: Hashable {
        let model: Model

        struct Link: Hashable {
            let title: String
            let url: URL
        }
    }

}

extension SettingScreen.TeamSection.Row.ViewModel {

    var name: String { model.name }
    var role: String { model.role }

    var links: [Link] {
        model.links.map {
            .init(title: $0.title, url: $0.url)
        }
    }

}

#Preview {
    Form {
        SettingScreen.TeamSection(
            viewModel: .init(
                model: .init(
                    rows: [
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
                    ]
                )
            )
        )
    }
}
