
import SwiftUI

import ComposableArchitecture

extension SettingScreen {

    struct GeneralSection: View {
        let store: StoreOf<Root.Feature>

        var body: some View {
            Section("일반") {
                Picker(
                    "화면 모드",
                    selection: Binding(
                        get: { store.displayMode },
                        set: { store.send(.view(.displayModeChanged($0))) }
                    )
                ) {
                    ForEach(DisplayMode.allCases, id: \.self) {
                        Text(title($0))
                            .tag($0)
                    }
                }
                Picker(
                    "건너뛰기 시간",
                    selection: Binding(
                        get: { store.skipInterval },
                        set: { store.send(.view(.skipIntervalChanged($0))) }
                    )
                ) {
                    ForEach(SkipInterval.allCases, id: \.self) {
                        Text("\($0.rawValue)초")
                            .tag($0)
                    }
                }
                Toggle(
                    "화면 자동 잠금 끄기",
                    isOn: Binding(
                        get: { store.isIdleTimerDisabled },
                        set: { store.send(.view(.idleTimerDisabledChanged($0))) }
                    )
                )
                Button(
                    action: { store.send(.view(.tutorialButtonTapped)) },
                    label: {
                        Text("앱 사용방법 다시보기")
                    }
                )
                .tint(.primary)
            }
        }
    }

}

extension SettingScreen.GeneralSection {

    private func title(_ displayMode: DisplayMode) -> String {
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
            store: .init(
                initialState: .init(),
                reducer: { SettingScreen.Root.Feature() }
            )
        )
    }
}
