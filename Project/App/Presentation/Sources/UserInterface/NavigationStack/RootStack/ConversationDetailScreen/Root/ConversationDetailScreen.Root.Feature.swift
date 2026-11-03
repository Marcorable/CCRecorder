
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.continuousClock) private var clock
        @Dependency(\.managingConversationUsecase) private var managingConversationUsecase
        @Dependency(\.navigator) private var navigator

        var body: some ReducerOf<Self> {
            Scope(state: \.editor, action: \.editor) {
                ConversationDetailScreen.Editor.Feature()
            }
            Scope(state: \.playbackPanel, action: \.playbackPanel) {
                ConversationDetailScreen.PlaybackPanel.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .noteDetail(.dismiss):
                        return .send(.editor(.parent(.noteDetailDismissed)))

                    case .editor(.delegate(.noteSelected(let id))):
                        state.noteDetail = .init(noteID: id)
                        return .none

                    case .editor(.delegate(.noteIDsUpdated(let ids))):
                        state.conversation?.noteIds = ids
                        return .none

                    case .editor(.delegate(.titleChanged(let title))):
                        guard var conversation = state.conversation else {
                            return .none
                        }
                        conversation.title = title
                        return .send(.conversationUpdateRequested(conversation))

                    case .editor(.delegate(.topicChanged(let topic))):
                        guard var conversation = state.conversation else {
                            return .none
                        }
                        conversation.topic = topic
                        return .send(.conversationUpdateRequested(conversation))

                    case .editor(.delegate(.partyAdded(let id, let name))):
                        guard var conversation = state.conversation else {
                            return .none
                        }
                        conversation.parties.append(.init(
                            id: id,
                            name: name
                        ))
                        return .send(.conversationUpdateRequested(conversation))

                    case .editor(.delegate(.partyRemoved(let id))):
                        guard var conversation = state.conversation else {
                            return .none
                        }
                        conversation.parties.removeAll(where: { $0.id == id })
                        return .send(.conversationUpdateRequested(conversation))

                    case .playbackPanel(.delegate(.failed(let failure))):
                        let message = switch failure {
                            case .fileNotFound:  "녹음 파일을 찾을 수 없습니다"
                            case .prepareFailed: "녹음 파일을 준비하지 못했습니다"
                        }
                        state.alert = .playbackFailed(message: message)
                        return .none

                    case .playbackPanel(.delegate(.interrupted)):
                        state.alert = .playbackInterrupted
                        return .none

                    case .alert(.presented(.close)):
                        return .run { _ in await navigator.pop() }

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

                    case .editor, .playbackPanel, .noteDetail, .alert:
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
                        .send(.editor(.parent(.conversationDetailDisappeared))),
                        .send(.playbackPanel(.parent(.conversationDetailDisappeared)))
                    )
                )
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
                    .send(.editor(.parent(.conversationLoaded(
                        createdDate: conversation.createdDate,
                        title: conversation.title,
                        topic: conversation.topic,
                        parties: conversation.parties.map({ party in
                            .init(
                                id: party.id,
                                name: party.name
                            )
                        })
                    )))),
                    .send(.playbackPanel(.parent(.conversationLoaded(
                        fileName: conversation.recordFileName,
                        pins: conversation.pins
                    ))))
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
        fileprivate var conversation: Conversation?
        var conversationLoadFailed = false
        var conversationUpdateRevision = 0
        var persistedConversationRevision = 0
        var isPersistingConversation = false
        var editor: ConversationDetailScreen.Editor.Feature.State
        var playbackPanel: ConversationDetailScreen.PlaybackPanel.Feature.State = .init()
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var noteDetail: NoteDetailScreen.Root.Feature.State?

        init(conversationID: Conversation.ID) {
            self.conversationID = conversationID
            self.editor = .init(conversationID: conversationID)
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
        case editor(ConversationDetailScreen.Editor.Feature.Action)
        case playbackPanel(ConversationDetailScreen.PlaybackPanel.Feature.Action)
        case noteDetail(PresentationAction<NoteDetailScreen.Root.Feature.Action>)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case appeared
            case disappeared
        }

        @CasePathable
        enum Response {
            case conversationLoaded(Result<Conversation?, DomainError>)
            case conversationPersisted(
                revision: Int,
                TaskResult<Void>
            )
        }

        enum Alert: Equatable {
            case close
        }
    }

}
