
import Domain
import ComposableArchitecture

extension MainScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.navigator) private var navigator
        @Dependency(\.recordingUsecase) private var recordingUsecase

        var body: some ReducerOf<Self> {
            Scope(
                state: \.conversationList,
                action: \.conversationList
            ) {
                MainScreen.ConversationList.Feature()
            }
            Scope(
                state: \.noteList,
                action: \.noteList
            ) {
                MainScreen.NoteList.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .conversationList(.delegate(let action)):
                        return reduce(into: &state, action: action)

                    case .noteList(.delegate(let action)):
                        return reduce(into: &state, action: action)

                    case .record(.dismiss):
                        let reloadEffect: Effect<Action> = switch state.selectedTab {
                            case .conversationList:
                                .send(.conversationList(.view(.reload)))

                            case .noteList:
                                .send(.noteList(.view(.reload)))
                        }
                        guard state.record?.isFinished == false else {
                            return reloadEffect
                        }
                        return .merge(
                            .run { _ in
                                await recordingUsecase.cancel()
                            },
                            reloadEffect
                        )

                    case .onboard(.dismiss):
                        state.$isFirstLaunched.withLock { $0 = false }
                        return .none

                    case .noteDetail(.dismiss):
                        return .send(.noteList(.noteDetailDismissed))

                    case .alert(.presented(let action)):
                        return reduce(into: &state, action: action)

                    case .conversationList, .noteList, .onboard, .record, .noteDetail, .alert:
                        return .none
                }
            }
            .ifLet(\.$onboard, action: \.onboard) {
                OnboardScreen.Root.Feature()
            }
            .ifLet(\.$record, action: \.record) {
                RecordScreen.Root.Feature()
            }
            .ifLet(\.$noteDetail, action: \.noteDetail) {
                NoteDetailScreen.Root.Feature()
            }
            .ifLet(\.$alert, action: \.alert)
        }
    }

}

extension MainScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .recordButtonTapped:
                state.record = .init()
                return .none

            case .settingButtonTapped:
                return .run { _ in
                    await navigator.push(.setting)
                }
        }
    }

    private func reduce(
        into state: inout State,
        action: MainScreen.ConversationList.Feature.Action.Delegate
    ) -> Effect<Action> {
        switch action {
            case .conversationSelected(let id):
                return .run { _ in
                    await navigator.push(.conversationDetail(id))
                }

            case .loadFailed:
                state.alert = .conversationLoadFailed
                return .none

            case .deleteFailed:
                state.alert = .conversationDeleteFailed
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: MainScreen.NoteList.Feature.Action.Delegate
    ) -> Effect<Action> {
        switch action {
            case .noteSelected(let id):
                state.noteDetail = .init(noteID: id)
                return .none

            case .loadFailed:
                state.alert = .noteLoadFailed
                return .none

            case .deleteFailed:
                state.alert = .noteDeleteFailed
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Alert
    ) -> Effect<Action> {
        switch action {
            case .retryConversationLoad:
                return .send(.conversationList(.view(.reload)))

            case .retryNoteLoad:
                return .send(.noteList(.view(.reload)))
        }
    }

}

extension MainScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        @Shared(.appStorage(.isFirstLaunched)) var isFirstLaunched: Bool = true

        @Presents var onboard: OnboardScreen.Root.Feature.State?
        @Presents var record: RecordScreen.Root.Feature.State?
        @Presents var noteDetail: NoteDetailScreen.Root.Feature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var conversationList: MainScreen.ConversationList.Feature.State = .init()
        var noteList: MainScreen.NoteList.Feature.State = .init()
        var selectedTab: MainScreen.Tab = .conversationList

        init() {
            if isFirstLaunched {
                onboard = .init()
            }
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case conversationList(MainScreen.ConversationList.Feature.Action)
        case noteList(MainScreen.NoteList.Feature.Action)
        case onboard(PresentationAction<OnboardScreen.Root.Feature.Action>)
        case record(PresentationAction<RecordScreen.Root.Feature.Action>)
        case noteDetail(PresentationAction<NoteDetailScreen.Root.Feature.Action>)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case tabSelected(MainScreen.Tab)
            case recordButtonTapped
            case settingButtonTapped
        }

        @CasePathable
        enum Alert: Equatable {
            case retryConversationLoad
            case retryNoteLoad
        }

    }

}
