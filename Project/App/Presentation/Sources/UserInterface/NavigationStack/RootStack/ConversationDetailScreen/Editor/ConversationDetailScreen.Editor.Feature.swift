
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
        var title = ""
        var createdDate: Date?
        var topic = ""
        var parties: [Party] = []
        var partyInput = ""
        var isEditing = false
        var noteInput = ""
        var rows: [NoteBoard.Row.ViewModel]?
        var isLoading = false

        struct Party: Equatable, Identifiable {
            let id: UUID
            let name: String
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case parent(Parent)
        case view(View)
        case response(Response)
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
            case notesLoading
            case notesLoaded(Result<[Note], DomainError>)
            case noteAdding(String)
            case noteAdded(TaskResult<[UUID]>)
            case notesDeleting([UUID])
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
                state.createdDate = createdDate
                state.title = title
                state.topic = topic
                state.parties = parties
                state.rows = nil
                state.isLoading = true
                return .send(.response(.notesLoading))

            case .noteDetailDismissed:
                state.isLoading = true
                return .send(.response(.notesLoading))

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
                guard !state.isLoading else {
                    return .none
                }
                state.noteInput = input
                return .none

            case .noteAdded:
                guard
                    !state.isLoading,
                    !state.noteInput.isEmpty
                else {
                    return .none
                }
                let input = state.noteInput
                state.noteInput = ""
                state.isLoading = true
                return .send(.response(.noteAdding(input)))

            case .notesDeleted(let ids):
                guard
                    !state.isLoading,
                    !ids.isEmpty
                else {
                    return .none
                }
                state.isLoading = true
                return .send(.response(.notesDeleting(ids)))

            case .noteSelected(let id):
                guard
                    !state.isLoading,
                    state.rows?.contains(where: { $0.id == id }) == true
                else {
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
            case .notesLoading:
                let conversationID = state.conversationID
                return .run { send in
                    await send(.response(.notesLoaded(
                        await managingConversationUsecase.notes(conversationID)
                    )))
                }
                .cancellable(
                    id: CancelID.loadNotes,
                    cancelInFlight: true
                )

            case .notesLoaded(.success(let notes)):
                state.isLoading = false
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
                state.isLoading = false
                if state.rows == nil {
                    state.rows = []
                }
                return .none

            case .noteAdding(let input):
                let conversationID = state.conversationID
                return .run { send in
                    await send(.response(.noteAdded(
                        TaskResult {
                            try await managingConversationUsecase.addNote(
                                input,
                                conversationID
                            )
                            .noteIds
                        }
                    )))
                }

            case .notesDeleting(let ids):
                let conversationID = state.conversationID
                return .run { send in
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

            case .noteAdded(.success(let ids)),
                 .notesDeleted(.success(let ids)):
                return .merge(
                    .send(.delegate(.noteIDsUpdated(ids))),
                    .send(.response(.notesLoading))
                )

            case .noteAdded(.failure),
                 .notesDeleted(.failure):
                state.isLoading = false
                return .none
        }
    }

}
