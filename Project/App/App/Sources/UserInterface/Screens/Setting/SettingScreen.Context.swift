
import SwiftUI

extension SettingScreen {

    struct Context: View {
        @AppStorage(.displayMode) private var displayMode: DisplayMode = .system
        @AppStorage(.skipInterval) private var skipInterval: SkipInterval = .five
        @AppStorage(.isIdleTimerDisabled) private var isIdleTimerDisabled: Bool = false

        @State private var viewModel: ViewModel

        init(viewModel: ViewModel) {
            self._viewModel = .init(initialValue: viewModel)
        }

        var body: some View {
            Form {
                GeneralSection(
                    displayMode: $displayMode,
                    skipInterval: $skipInterval,
                    isIdleTimerDisabled: $isIdleTimerDisabled
                )
                InformationSection(viewModel: viewModel.informationSection)
                TeamSection(viewModel: viewModel.teamSection)
            }
            .environment(viewModel)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $viewModel.presentedFullScreenCover) {
                switch $0 {
                    case .tutorial:
                        OnboardScreen.Context()
                }
            }
        }
    }

}

#if DEBUG
#Preview {
    NavigationStack {
        SettingScreen.Context(viewModel: .mock)
    }
}
#endif
