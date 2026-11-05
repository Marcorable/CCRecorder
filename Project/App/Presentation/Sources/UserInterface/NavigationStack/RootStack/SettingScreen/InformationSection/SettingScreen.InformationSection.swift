
import UIKit
import SwiftUI

extension SettingScreen {

    struct InformationSection: View {
        let appVersion: String

        var body: some View {
            Section("앱 정보") {
                LabeledContent("버전", value: appVersion)
                Link(
                    destination: URL(string: UIApplication.openSettingsURLString)!,
                    label: {
                        Label(
                            "오픈소스 라이선스",
                            systemImage: "arrow.up.forward"
                        )
                    }
                )
                Link(
                    destination: URL(string: "https://www.instagram.com/casualconversation_ccrecorder/")!,
                    label: {
                        Label(
                            "인스타그램 소통하기",
                            systemImage: "hand.thumbsup"
                        )
                    }
                )
                Link(
                    destination: URL(string: "mailto:pse.applications@gmail.com")!,
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
