
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
            Scope(
                state: \.editor,
                action: \.editor
            ) {
                ConversationDetailScreen.Editor.Feature()
            }
            Scope(
                state: \.playbackPanel,
                action: \.playbackPanel
            ) {
                ConversationDetailScreen.PlaybackPanel.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .editor(.delegate(let action)):
                        return reduce(into: &state, action: action)

                    case .playbackPanel(.delegate(let action)):
                        return reduce(into: &state, action: action)

                    case .alert(.presented(let action)):
                        return reduce(into: &state, action: action)

                    case .noteDetail(.dismiss):
                        return .send(.editor(.parent(.noteDetailDismissed)))

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

    typealias EditorDelegate = ConversationDetailScreen.Editor.Feature.Action.Delegate
    typealias PlaybackPanelDelegate = ConversationDetailScreen.PlaybackPanel.Feature.Action.Delegate

    @ObservableState
    struct State: Equatable {
        let conversationID: Conversation.ID
        var conversationLoadFailed = false
        var conversationUpdateRevision = 0
        var persistedConversationRevision = 0
        var isPersistingConversation = false

        var editor: ConversationDetailScreen.Editor.Feature.State
        var playbackPanel: ConversationDetailScreen.PlaybackPanel.Feature.State = .init()

        init(conversationID: Conversation.ID) {
            self.conversationID = conversationID
            self.editor = .init(conversationID: conversationID)
        }

        @Presents var alert: AlertState<Action.Alert>?
        @Presents var noteDetail: NoteDetailScreen.Root.Feature.State?

        fileprivate var conversation: Conversation?
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case response(Response)
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
            case conversationLoading
            case conversationLoaded(Result<Conversation?, DomainError>)
            case conversationUpdating(Conversation)
            case conversationPersisting(
                revision: Int,
                conversation: Conversation
            )
            case conversationPersisted(
                revision: Int,
                TaskResult<Void>
            )
        }

        enum Alert: Equatable {
            case close
        }
    }

    private enum CancelID {
        case loadConversation
        case update
    }

}

extension ConversationDetailScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .appeared:
                return .send(.response(.conversationLoading))

            case .disappeared:
                let persistence: Effect<Action> = if let conversation = state.conversation,
                                                     state.persistedConversationRevision
                                                     < state.conversationUpdateRevision {
                    .send(.response(.conversationPersisting(
                        revision: state.conversationUpdateRevision,
                        conversation: conversation
                    )))
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
            case .conversationLoading:
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

            case .conversationUpdating(let conversation):
                state.conversation = conversation
                state.conversationUpdateRevision += 1
                let revision = state.conversationUpdateRevision
                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                    await send(.response(.conversationPersisting(
                        revision: revision,
                        conversation: conversation
                    )))
                }
                .cancellable(
                    id: CancelID.update,
                    cancelInFlight: true
                )

            case .conversationPersisting(let revision, let conversation):
                guard !state.isPersistingConversation else {
                    return .none
                }
                state.isPersistingConversation = true
                return .run { send in
                    await send(.response(.conversationPersisted(
                        revision: revision,
                        TaskResult {
                            try await managingConversationUsecase.update(conversation)
                        }
                    )))
                }

            case .conversationPersisted(let revision, let result):
                state.isPersistingConversation = false
                if case .success = result {
                    state.persistedConversationRevision = max(
                        state.persistedConversationRevision,
                        revision
                    )
                }
                guard
                    let conversation = state.conversation,
                    revision < state.conversationUpdateRevision
                else {
                    return .none
                }
                return .send(.response(.conversationPersisting(
                    revision: state.conversationUpdateRevision,
                    conversation: conversation
                )))
        }
    }

    private func reduce(
        into state: inout State,
        action: EditorDelegate
    ) -> Effect<Action> {
        switch action {
            case .noteSelected(let id):
                state.noteDetail = .init(noteID: id)
                return .none

            case .noteIDsUpdated(let ids):
                state.conversation?.noteIds = ids
                return .none

            case .titleChanged(let title):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.title = title
                return .send(.response(.conversationUpdating(conversation)))

            case .topicChanged(let topic):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.topic = topic
                return .send(.response(.conversationUpdating(conversation)))

            case .partyAdded(let id, let name):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.parties.append(.init(
                    id: id,
                    name: name
                ))
                return .send(.response(.conversationUpdating(conversation)))

            case .partyRemoved(let id):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.parties.removeAll(where: { $0.id == id })
                return .send(.response(.conversationUpdating(conversation)))
        }
    }

    private func reduce(
        into state: inout State,
        action: PlaybackPanelDelegate
    ) -> Effect<Action> {
        switch action {
            case .failed(let failure):
                let message = switch failure {
                    case .fileNotFound:  "녹음 파일을 찾을 수 없습니다"
                    case .prepareFailed: "녹음 파일을 준비하지 못했습니다"
                }
                state.alert = .playbackFailed(message: message)
                return .none

            case .interrupted:
                state.alert = .playbackInterrupted
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Alert
    ) -> Effect<Action> {
        switch action {
            case .close:
                return .run { _ in await navigator.pop() }
        }
    }

}
