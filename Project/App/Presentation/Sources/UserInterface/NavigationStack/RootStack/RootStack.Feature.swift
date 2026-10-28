
import Domain
import ComposableArchitecture

extension RootStack {

    @Reducer
    struct Feature {
        let managingConversationUsecase: ManagingConversationUsecase
        let managingNoteUsecase: ManagingNoteUsecase
        let playingRecordUsecase: PlayingRecordUsecase
        let recordingUsecase: RecordingUsecase

        var body: some ReducerOf<Self> {
            Scope(
                state: \.main,
                action: \.main
            ) {
                MainScreen.Root.Feature(
                    managingConversationUsecase: managingConversationUsecase,
                    managingNoteUsecase: managingNoteUsecase,
                    recordingUsecase: recordingUsecase
                )
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
            .forEach(\.path, action: \.path) {
                Path(
                    managingConversationUsecase: managingConversationUsecase,
                    playingRecordUsecase: playingRecordUsecase
                )
            }
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
    struct Path {
        let managingConversationUsecase: ManagingConversationUsecase
        let playingRecordUsecase: PlayingRecordUsecase

        var body: some ReducerOf<Self> {
            Reduce { _, _ in .none }
            .ifCaseLet(
                \.conversationDetail,
                action: \.conversationDetail
            ) {
                ConversationDetailScreen.Root.Feature(
                    managingConversationUsecase: managingConversationUsecase,
                    playingRecordUsecase: playingRecordUsecase
                )
            }
            .ifCaseLet(
                \.setting,
                action: \.setting
            ) {
                SettingScreen.Root.Feature()
            }
        }
    }

}

extension RootStack.Feature.Path {

    @CasePathable
    @dynamicMemberLookup
    @ObservableState
    enum State: Equatable {
        case conversationDetail(ConversationDetailScreen.Root.Feature.State)
        case setting(SettingScreen.Root.Feature.State)
    }

    @CasePathable
    enum Action {
        case conversationDetail(ConversationDetailScreen.Root.Feature.Action)
        case setting(SettingScreen.Root.Feature.Action)
    }

}

#if DEBUG
extension RootStack.Feature {

    @MainActor
    static var preview: Self {
        .init(
            managingConversationUsecase: FakeManagingConversationUsecase(),
            managingNoteUsecase: FakeManagingNoteUsecase(),
            playingRecordUsecase: FakePlayingRecordUsecase(),
            recordingUsecase: FakeRecordingUsecase()
        )
    }

}
#endif
