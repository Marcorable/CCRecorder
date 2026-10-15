
import SwiftUI

extension SettingScreen {

    struct GeneralSection: View {
        @Binding var displayMode: DisplayMode
        @Binding var skipInterval: SkipInterval
        @Binding var isIdleTimerDisabled: Bool

        let presentTutorial: () -> Void

        var body: some View {
            Section(
                content: {
                    Picker("화면 모드", selection: $displayMode) {
                        ForEach(DisplayMode.allCases, id: \.self) {
                            Text(title($0))
                                .tag($0)
                        }
                    }
                    Picker("건너뛰기 시간", selection: $skipInterval) {
                        ForEach(SkipInterval.allCases, id: \.self) {
                            Text("\($0.rawValue)초")
                                .tag($0)
                        }
                    }
                    Toggle("화면 자동 잠금 끄기", isOn: $isIdleTimerDisabled)
                    Button(
                        action: presentTutorial,
                        label: { Text("앱 사용방법 다시보기") }
                    )
                    .tint(.primary)
                },
                header: { Text("일반") }
            )
        }
    }

}

extension SettingScreen.GeneralSection {

    func title(_ displayMode: DisplayMode) -> String {
        switch displayMode {
            case .system:
                "기기 설정에 따름"

            case .light:
                "라이트 모드"

            case .dark:
                "다크 모드"
        }
    }

}

#Preview {
    Form {
        SettingScreen.GeneralSection(
            displayMode: .constant(.system),
            skipInterval: .constant(.five),
            isIdleTimerDisabled: .constant(false),
            presentTutorial: {}
        )
    }
}
