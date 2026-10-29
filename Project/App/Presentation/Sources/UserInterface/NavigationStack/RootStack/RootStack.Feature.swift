
import Domain
import ComposableArchitecture

extension RootStack {

    @Reducer
    struct Feature {
        var body: some ReducerOf<Self> {
            Scope(
                state: \.main,
                action: \.main
            ) {
                MainScreen.Root.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .main(.delegate(.conversationSelected(let conversation))):
                        state.path.append(.conversationDetail(.init(conversation: conversation)))
                        return .none

                    case .main(.delegate(.settingRequested)):
                        state.path.append(.setting(.init()))
                        return .none

                    case .main, .path:
                        return .none
                }
            }
            .forEach(\.path, action: \.path)
        }
    }

}

extension RootStack.Feature {

    @ObservableState
    struct State: Equatable {
        var main: MainScreen.Root.Feature.State = .init()
        var path: StackState<Path.State> = .init()
    }

    @CasePathable
    enum Action {
        case main(MainScreen.Root.Feature.Action)
        case path(StackActionOf<Path>)
    }

    @Reducer
    enum Path {
        case conversationDetail(ConversationDetailScreen.Root.Feature)
        case setting(SettingScreen.Root.Feature)
    }

}

extension RootStack.Feature.Path.State: Equatable {}

#if DEBUG
extension RootStack.Feature {

    @MainActor
    static var preview: Self {
        .init()
    }

}
#endif
