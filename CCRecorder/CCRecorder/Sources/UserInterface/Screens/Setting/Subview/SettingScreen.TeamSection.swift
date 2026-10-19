
import SwiftUI

extension SettingScreen {

    struct TeamSection: View {
        let teamMates: [TeamMate]

        var body: some View {
            Section("Team Marcoda") {
                ForEach(teamMates, id: \.self) {
                    Row(teamMate: $0)
                }
            }
        }
    }

}

extension SettingScreen.TeamSection {

    struct Row: View {
        let teamMate: SettingScreen.TeamMate

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(teamMate.name)
                    .font(.headline)
                Text(teamMate.role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(teamMate.links, id: \.self) {
                        Link($0.title, destination: $0.url)
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }

}

#Preview {
    Form {
        SettingScreen.TeamSection(teamMates: SettingScreen.teamMates)
    }
}
