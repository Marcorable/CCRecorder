
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.Editor {

    @Reducer
    struct Feature {
        @Dependency(\.uuid) private var uuid
        @Dependency(\.managingConversationUsecase) private var managingConversationUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .parent(let action):
                        return reduce(into: &state, action: action)

                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .performNextMutation:
                        guard
                            !state.isMutating,
                            let mutation = state.pendingMutations.first
                        else {
                            return .none
                        }
                        state.isMutating = true
                        state.pendingMutations.removeFirst()
                        return mutate(
                            mutation,
                            conversationID: state.conversationID
                        )

                    case .delegate:
                        return .none
                }
            }
        }
    }

}

extension ConversationDetailScreen.Editor.Feature {

    @ObservableState
    struct State: Equatable {
        let conversationID: UUID
        var isLoaded = false
        var title = ""
        var createdDate: Date?
        var topic = ""
        var parties: [Party] = []
        var partyInput = ""
        var isEditing = false
        var noteInput = ""
        var rows: [NoteBoard.Row.ViewModel]?
        fileprivate var pendingMutations: [Mutation] = []
        fileprivate var isMutating = false

        var createdDateText: String {
            createdDate?.formatted(
                date: .abbreviated,
                time: .omitted
            ) ?? ""
        }

        struct Party: Equatable, Identifiable {
            let id: UUID
            let name: String
        }

        fileprivate enum Mutation: Equatable {
            case addition(String)
            case deletion([UUID])
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case parent(Parent)
        case view(View)
        case response(Response)
        case performNextMutation
        case delegate(Delegate)

        @CasePathable
        enum Parent {
            case conversationLoaded(
                createdDate: Date,
                title: String,
                topic: String,
                parties: [State.Party]
            )
            case noteDetailDismissed
            case conversationDetailDisappeared
        }

        @CasePathable
        enum View {
            case titleChanged(String)
            case topicChanged(String)
            case editingToggled
            case partyInputChanged(String)
            case partyAdded
            case partyRemoved(UUID)
            case noteInputChanged(String)
            case noteAdded
            case notesDeleted([UUID])
            case noteSelected(UUID)
        }

        @CasePathable
        enum Response {
            case notesLoaded(Result<[Note], DomainError>)
            case noteAdded(TaskResult<[UUID]>)
            case notesDeleted(TaskResult<[UUID]>)
        }

        @CasePathable
        enum Delegate {
            case titleChanged(String)
            case topicChanged(String)
            case partyAdded(
                id: UUID,
                name: String
            )
            case partyRemoved(UUID)
            case noteSelected(UUID)
            case noteIDsUpdated([UUID])
        }
    }

    private enum CancelID {
        case loadNotes
    }

}

extension ConversationDetailScreen.Editor.Feature {

    private func reduce(
        into state: inout State,
        action: Action.Parent
    ) -> Effect<Action> {
        switch action {
            case .conversationLoaded(
                let createdDate,
                let title,
                let topic,
                let parties
            ):
                state.isLoaded = true
                state.createdDate = createdDate
                state.title = title
                state.topic = topic
                state.parties = parties
                state.rows = nil
                return loadNotes(conversationID: state.conversationID)

            case .noteDetailDismissed:
                return loadNotes(conversationID: state.conversationID)

            case .conversationDetailDisappeared:
                return .cancel(id: CancelID.loadNotes)
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .titleChanged(let title):
                state.title = title
                return .send(.delegate(.titleChanged(title)))

            case .topicChanged(let topic):
                state.topic = topic
                return .send(.delegate(.topicChanged(topic)))

            case .editingToggled:
                state.isEditing.toggle()
                return .none

            case .partyInputChanged(let party):
                state.partyInput = party
                return .none

            case .partyAdded:
                guard !state.partyInput.isEmpty else {
                    return .none
                }
                let id = uuid()
                let name = state.partyInput
                state.partyInput = ""
                state.parties.append(.init(
                    id: id,
                    name: name
                ))
                return .send(.delegate(.partyAdded(
                    id: id,
                    name: name
                )))

            case .partyRemoved(let id):
                guard state.parties.contains(where: { $0.id == id }) else {
                    return .none
                }
                state.parties.removeAll(where: { $0.id == id })
                return .send(.delegate(.partyRemoved(id)))

            case .noteInputChanged(let input):
                state.noteInput = input
                return .none

            case .noteAdded:
                guard !state.noteInput.isEmpty else {
                    return .none
                }
                let input = state.noteInput
                state.noteInput = ""
                state.pendingMutations.append(.addition(input))
                return .send(.performNextMutation)

            case .notesDeleted(let ids):
                guard !ids.isEmpty else {
                    return .none
                }
                state.pendingMutations.append(.deletion(ids))
                return .send(.performNextMutation)

            case .noteSelected(let id):
                guard state.rows?.contains(where: { $0.id == id }) == true else {
                    return .none
                }
                return .send(.delegate(.noteSelected(id)))
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .notesLoaded(.success(let notes)):
                state.rows = notes.map({ note in
                    .init(
                        id: note.id,
                        original: note.original,
                        translation: note.translation,
                        isVocabulary: note.category == .vocabulary
                    )
                })
                return .none

            case .notesLoaded(.failure):
                if state.rows == nil {
                    state.rows = []
                }
                return .none

            case .noteAdded(.success(let ids)),
                 .notesDeleted(.success(let ids)):
                state.isMutating = false
                return .merge(
                    .send(.delegate(.noteIDsUpdated(ids))),
                    loadNotes(conversationID: state.conversationID),
                    .send(.performNextMutation)
                )

            case .noteAdded(.failure),
                 .notesDeleted(.failure):
                state.isMutating = false
                return .send(.performNextMutation)
        }
    }

    private func loadNotes(
        conversationID: Conversation.ID
    ) -> Effect<Action> {
        .run { send in
            await send(.response(.notesLoaded(
                await managingConversationUsecase.notes(conversationID)
            )))
        }
        .cancellable(
            id: CancelID.loadNotes,
            cancelInFlight: true
        )
    }

    private func mutate(
        _ mutation: State.Mutation,
        conversationID: Conversation.ID
    ) -> Effect<Action> {
        .run { send in
            switch mutation {
                case .addition(let input):
                    await send(.response(.noteAdded(
                        TaskResult {
                            try await managingConversationUsecase.addNote(
                                input,
                                conversationID
                            )
                            .noteIds
                        }
                    )))

                case .deletion(let ids):
                    await send(.response(.notesDeleted(
                        TaskResult {
                            try await managingConversationUsecase.deleteNotes(
                                ids,
                                conversationID
                            )
                            .noteIds
                        }
                    )))
            }
        }
    }

}
