
import SwiftUI

extension SettingScreen {

    struct InformationSection: View {
        let appVersion: String?

        var body: some View {
            Section(
                content: {
                    LabeledContent("버전", value: appVersion ?? "알 수 없음")
                    Link(
                        destination: SettingScreen.repositoryURL,
                        label: { Label("오픈소스 (GitHub)", systemImage: "chevron.left.forwardslash.chevron.right") }
                    )
                    Link(
                        destination: SettingScreen.instagramURL,
                        label: { Label("인스타그램 소통하기", systemImage: "hand.thumbsup") }
                    )
                    Link(
                        destination: SettingScreen.mailURL,
                        label: { Label("문의하기", systemImage: "envelope.open") }
                    )
                },
                header: { Text("앱 정보") }
            )
            .tint(.primary)
        }
    }

}

#Preview {
    Form {
        SettingScreen.InformationSection(appVersion: "1.0")
    }
}
