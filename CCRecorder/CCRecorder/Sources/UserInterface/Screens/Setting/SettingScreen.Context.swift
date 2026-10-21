
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
                    isIdleTimerDisabled: $isIdleTimerDisabled,
                    presentTutorial: { viewModel.reduce(by: .presentTutorial) }
                )
                InformationSection(appVersion: viewModel.appVersion)
                TeamSection(teamMates: SettingScreen.teamMates)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: isPresentedTutorial) {
                OnboardScreen.Context(isPrsented: isPresentedTutorial)
            }
        }
    }

}

extension SettingScreen.Context {

    private var isPresentedTutorial: Binding<Bool> {
        .init(
            get: { viewModel.isPresentedTutorial },
            set: { isPresented in
                guard !isPresented else { return }
                viewModel.reduce(by: .dismissTutorial)
            }
        )
    }

}

#if DEBUG
#Preview {
    NavigationStack {
        SettingScreen.Context(viewModel: .mock)
    }
}
#endif
