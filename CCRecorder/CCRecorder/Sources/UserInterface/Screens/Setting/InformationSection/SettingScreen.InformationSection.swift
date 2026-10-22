
import SwiftUI

extension SettingScreen {

    struct InformationSection: View {
        let viewModel: ViewModel

        var body: some View {
            Section("앱 정보") {
                LabeledContent("버전", value: viewModel.appVersion)
                Link(
                    destination: viewModel.instagramURL,
                    label: {
                        Label(
                            "인스타그램 소통하기",
                            systemImage: "hand.thumbsup"
                        )
                    }
                )
                Link(
                    destination: viewModel.mailURL,
                    label: {
                        Label(
                            "문의하기",
                            systemImage: "envelope.open"
                        )
                    }
                )
            }
            .tint(.primary)
        }
    }

}

extension SettingScreen.InformationSection {

    struct Model {
        let appVersion: String?
        let instagramURL: URL
        let mailURL: URL
    }

    struct ViewModel {
        let model: Model
    }

}

extension SettingScreen.InformationSection.ViewModel {

    var appVersion: String {
        model.appVersion ?? "알 수 없음"
    }

    var instagramURL: URL { model.instagramURL }
    var mailURL: URL { model.mailURL }

}

#Preview {
    Form {
        SettingScreen.InformationSection(
            viewModel: .init(
                model: .init(
                    appVersion: "1.0",
                    instagramURL: URL(string: "https://www.instagram.com")!,
                    mailURL: URL(string: "mailto:preview@example.com")!
                )
            )
        )
    }
}
