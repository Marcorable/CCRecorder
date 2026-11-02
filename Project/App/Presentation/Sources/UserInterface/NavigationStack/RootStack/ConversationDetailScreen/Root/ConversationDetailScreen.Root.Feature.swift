
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.continuousClock) private var clock
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
                        state.conversation?.noteIds = conversation.noteIds
                        return .none

                    case .playbackPanel(.delegate(.failed(let failure))):
                        let message = switch failure {
                            case .fileNotFound:  "녹음 파일을 찾을 수 없습니다"
                            case .prepareFailed: "녹음 파일을 준비하지 못했습니다"
                        }
                        state.alert = .playbackFailed(message: message)
                        return .none

                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .conversationUpdateRequested(let conversation):
                        state.conversation = conversation
                        state.conversationUpdateRevision += 1
                        let revision = state.conversationUpdateRevision
                        return .run { send in
                            try await clock.sleep(for: .seconds(1))
                            await send(.conversationPersistenceRequested(
                                revision: revision,
                                conversation: conversation
                            ))
                        }
                        .cancellable(
                            id: CancelID.update,
                            cancelInFlight: true
                        )

                    case .conversationPersistenceRequested(
                        let revision,
                        let conversation
                    ):
                        guard !state.isPersistingConversation else {
                            return .none
                        }
                        state.isPersistingConversation = true
                        return persist(
                            revision: revision,
                            conversation: conversation
                        )

                    case .notes, .playbackPanel, .noteDetail, .alert:
                        return .none
                }
            }
            .ifLet(\.$noteDetail, action: \.noteDetail) {
                NoteDetailScreen.Root.Feature()
            }
            .ifLet(\.$alert, action: \.alert)
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
                let persistence: Effect<Action> = if let conversation = state.conversation,
                                                     state.persistedConversationRevision
                                                     < state.conversationUpdateRevision {
                    .send(.conversationPersistenceRequested(
                        revision: state.conversationUpdateRevision,
                        conversation: conversation
                    ))
                } else {
                    .none
                }
                return .concatenate(
                    .cancel(id: CancelID.loadConversation),
                    .cancel(id: CancelID.update),
                    .merge(
                        persistence,
                        .send(.notes(.cancel)),
                        .send(.playbackPanel(.finish))
                    )
                )

            case .titleChanged(let title):
                guard var updatingItem = state.conversation else {
                    return .none
                }
                updatingItem.title = title
                return .send(.conversationUpdateRequested(updatingItem))

            case .topicChanged(let topic):
                guard var updatingItem = state.conversation else {
                    return .none
                }
                updatingItem.topic = topic
                return .send(.conversationUpdateRequested(updatingItem))

            case .editingToggled:
                state.isEditing.toggle()
                return .none

            case .partyInputChanged(let party):
                state.partyInput = party
                return .none

            case .partyAdded:
                guard !state.partyInput.isEmpty, var updatingItem = state.conversation else {
                    return .none
                }
                updatingItem.parties.append(.init(name: state.partyInput))
                state.partyInput = ""
                return .send(.conversationUpdateRequested(updatingItem))

            case .partyRemoved(let id):
                guard var updatingItem = state.conversation else {
                    return .none
                }
                updatingItem.parties.removeAll(where: { $0.id == id })
                return .send(.conversationUpdateRequested(updatingItem))

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

            case .conversationPersisted(let revision, .success):
                state.isPersistingConversation = false
                state.persistedConversationRevision = max(
                    state.persistedConversationRevision,
                    revision
                )
                return persistLatestConversationIfNeeded(
                    after: revision,
                    state: state
                )

            case .conversationPersisted(let revision, .failure):
                state.isPersistingConversation = false
                return persistLatestConversationIfNeeded(
                    after: revision,
                    state: state
                )
        }
    }

    private func persistLatestConversationIfNeeded(
        after revision: Int,
        state: State
    ) -> Effect<Action> {
        guard
            let conversation = state.conversation,
            revision < state.conversationUpdateRevision
        else {
            return .none
        }
        return .send(.conversationPersistenceRequested(
            revision: state.conversationUpdateRevision,
            conversation: conversation
        ))
    }

    private func persist(
        revision: Int,
        conversation: Conversation
    ) -> Effect<Action> {
        .run { send in
            await send(.response(.conversationPersisted(
                revision: revision,
                TaskResult {
                    try await managingConversationUsecase.update(conversation)
                }
            )))
        }
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
        var conversationUpdateRevision = 0
        var persistedConversationRevision = 0
        var isPersistingConversation = false
        var partyInput = ""
        var isEditing = false
        var notes: ConversationDetailScreen.Notes.Feature.State
        var playbackPanel: ConversationDetailScreen.PlaybackPanel.Feature.State = .init()
        @Presents var alert: AlertState<Action.Alert>?
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
        case conversationUpdateRequested(Conversation)
        case conversationPersistenceRequested(
            revision: Int,
            conversation: Conversation
        )
        case notes(ConversationDetailScreen.Notes.Feature.Action)
        case playbackPanel(ConversationDetailScreen.PlaybackPanel.Feature.Action)
        case noteDetail(PresentationAction<NoteDetailScreen.Root.Feature.Action>)
        case alert(PresentationAction<Alert>)

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
        }

        @CasePathable
        enum Response {
            case conversationLoaded(Result<Conversation?, DomainError>)
            case conversationPersisted(
                revision: Int,
                TaskResult<Void>
            )
        }

        enum Alert: Equatable {}
    }

}
