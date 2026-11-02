
import ComposableArchitecture

extension OnboardScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.dismiss) private var dismiss

        var body: some ReducerOf<Self> {
            Reduce { _, action in
                switch action {
                    case .view(.startButtonTapped):
                        return .run { _ in
                            await dismiss()
                        }
                }
            }
        }
    }

}

extension OnboardScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {}

    @CasePathable
    enum Action: ViewAction {
        case view(View)

        @CasePathable
        enum View {
            case startButtonTapped
        }
    }

}
