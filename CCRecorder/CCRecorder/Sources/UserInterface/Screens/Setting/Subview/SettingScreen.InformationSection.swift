
import SwiftUI

extension SettingScreen {

    struct InformationSection: View {
        let appVersion: String?

        var body: some View {
            Section("앱 정보") {
                LabeledContent("버전", value: appVersion ?? "알 수 없음")
                Link(
                    destination: SettingScreen.instagramURL,
                    label: {
                        Label(
                            "인스타그램 소통하기",
                            systemImage: "hand.thumbsup"
                        )
                    }
                )
                Link(
                    destination: SettingScreen.mailURL,
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

#Preview {
    Form {
        SettingScreen.InformationSection(appVersion: "1.0")
    }
}
