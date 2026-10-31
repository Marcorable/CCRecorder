
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.managingConversationUsecase) private var managingConversationUsecase

        var body: some ReducerOf<Self> {
            Scope(state: \.notes, action: \.notes) {
                ConversationDetailScreen.Notes.Feature()
            }
            Scope(state: \.playbackPanel, action: \.playbackPanel) {
                ConversationDetailScreen.PlaybackPanel.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .noteDetail(.dismiss):
                        return .send(.notes(.load))

                    case .notes(.delegate(.noteSelected(let id))):
                        state.noteDetail = .init(noteID: id)
                        return .none

                    case .notes(.delegate(.conversationUpdated(let conversation))):
                        state.conversation = conversation
                        return .none

                    case .playbackPanel(.delegate(.failed(let failure))):
                        state.playbackFailure = failure
                        return .none

                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .notes, .playbackPanel, .noteDetail:
                        return .none
                }
            }
            .ifLet(\.$noteDetail, action: \.noteDetail) {
                NoteDetailScreen.Root.Feature()
            }
        }
    }

}

extension ConversationDetailScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .appeared:
                let id = state.conversationID
                return .run { send in
                    await send(.response(.conversationLoaded(
                        await managingConversationUsecase.conversation(id)
                    )))
                }
                .cancellable(
                    id: CancelID.loadConversation,
                    cancelInFlight: true
                )

            case .disappeared:
                return .merge(
                    .cancel(id: CancelID.loadConversation),
                    .cancel(id: CancelID.update),
                    .send(.notes(.cancel)),
                    .send(.playbackPanel(.finish))
                )

            case .titleChanged(let title):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.title = title
                state.conversation = conversation
                return update(conversation)

            case .topicChanged(let topic):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.topic = topic
                state.conversation = conversation
                return update(conversation)

            case .editingToggled:
                state.isEditing.toggle()
                return .none

            case .partyInputChanged(let party):
                state.partyInput = party
                return .none

            case .partyAdded:
                guard !state.partyInput.isEmpty, var conversation = state.conversation else {
                    return .none
                }
                conversation.parties.append(.init(name: state.partyInput))
                state.conversation = conversation
                state.partyInput = ""
                return update(conversation)

            case .partyRemoved(let id):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.parties.removeAll(where: { $0.id == id })
                state.conversation = conversation
                return update(conversation)

            case .alertDismissed:
                state.playbackFailure = nil
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .conversationLoaded(.success(let conversation)):
                state.conversation = conversation
                state.conversationLoadFailed = conversation == nil
                guard let conversation else {
                    return .none
                }
                return .merge(
                    .send(.notes(.load)),
                    .send(.playbackPanel(.prepare(
                        fileName: conversation.recordFileName,
                        pins: conversation.pins
                    )))
                )

            case .conversationLoaded(.failure):
                state.conversationLoadFailed = true
                return .none
        }
    }

    private func update(_ conversation: Conversation) -> Effect<Action> {
        .run { _ in
            try await Task.sleep(for: .seconds(1))
            try await managingConversationUsecase.update(conversation)
        }
        .cancellable(id: CancelID.update, cancelInFlight: true)
    }

    private enum CancelID {
        case loadConversation
        case update
    }

}

extension ConversationDetailScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        let conversationID: Conversation.ID
        var conversation: Conversation?
        var conversationLoadFailed = false
        var partyInput = ""
        var isEditing = false
        var notes: ConversationDetailScreen.Notes.Feature.State
        var playbackPanel: ConversationDetailScreen.PlaybackPanel.Feature.State = .init()
        var playbackFailure: ConversationDetailScreen.PlaybackPanel.Feature.State.Failure?
        @Presents var noteDetail: NoteDetailScreen.Root.Feature.State?

        init(conversationID: Conversation.ID) {
            self.conversationID = conversationID
            self.notes = .init(conversationID: conversationID)
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case response(Response)
        case notes(ConversationDetailScreen.Notes.Feature.Action)
        case playbackPanel(ConversationDetailScreen.PlaybackPanel.Feature.Action)
        case noteDetail(PresentationAction<NoteDetailScreen.Root.Feature.Action>)

        @CasePathable
        enum View {
            case appeared
            case disappeared
            case titleChanged(String)
            case topicChanged(String)
            case editingToggled
            case partyInputChanged(String)
            case partyAdded
            case partyRemoved(Party.ID)
            case alertDismissed
        }

        @CasePathable
        enum Response {
            case conversationLoaded(Result<Conversation?, DomainError>)
        }
    }

}
