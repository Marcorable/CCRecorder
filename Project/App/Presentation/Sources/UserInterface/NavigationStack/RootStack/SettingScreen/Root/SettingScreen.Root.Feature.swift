
import Foundation

import ComposableArchitecture

extension SettingScreen.Root {

    @Reducer
    struct Feature {
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .view(.displayModeChanged(let displayMode)):
                        state.$displayMode.withLock { $0 = displayMode }
                        return .none

                    case .view(.skipIntervalChanged(let skipInterval)):
                        state.$skipInterval.withLock { $0 = skipInterval }
                        return .none

                    case .view(.idleTimerDisabledChanged(let isDisabled)):
                        state.$isIdleTimerDisabled.withLock { $0 = isDisabled }
                        return .none

                    case .view(.tutorialButtonTapped):
                        state.tutorial = .init()
                        return .none

                    case .tutorial:
                        return .none
                }
            }
            .ifLet(\.$tutorial, action: \.tutorial) {
                OnboardScreen.Root.Feature()
            }
        }
    }

}

extension SettingScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        @Shared(.appStorage(.displayMode)) var displayMode: DisplayMode = .system
        @Shared(.appStorage(.skipInterval)) var skipInterval: SkipInterval = .five
        @Shared(.appStorage(.isIdleTimerDisabled)) var isIdleTimerDisabled: Bool = false
        @Presents var tutorial: OnboardScreen.Root.Feature.State?

        let appVersion: String

        init(bundle: Bundle = .main) {
            self.appVersion = bundle.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "알 수 없음"
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case tutorial(PresentationAction<OnboardScreen.Root.Feature.Action>)

        @CasePathable
        enum View {
            case displayModeChanged(DisplayMode)
            case skipIntervalChanged(SkipInterval)
            case idleTimerDisabledChanged(Bool)
            case tutorialButtonTapped
        }
    }

}
