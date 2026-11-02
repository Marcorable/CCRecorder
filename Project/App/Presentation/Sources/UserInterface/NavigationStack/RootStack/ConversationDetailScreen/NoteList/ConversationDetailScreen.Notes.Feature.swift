
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen {

    enum Notes {}

}

extension ConversationDetailScreen.Notes {

    @Reducer
    struct Feature {
        @Dependency(\.managingConversationUsecase) private var managingConversationUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .load:
                        return loadNotes(conversationID: state.conversationID)

                    case .cancel:
                        return .cancel(id: CancelID.load)

                    case .view(.noteInputChanged(let input)):
                        state.noteInput = input
                        return .none

                    case .view(.noteAdded):
                        let input = state.noteInput
                        guard !input.isEmpty else {
                            return .none
                        }
                        state.noteInput = ""
                        state.pendingMutations.append(.addition(input))
                        return .send(.performNextMutation)

                    case .view(.notesDeleted(let offsets)):
                        let ids = offsets.map { state.notes[$0].id }
                        state.pendingMutations.append(.deletion(ids))
                        return .send(.performNextMutation)

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

                    case .view(.noteSelected(let id)):
                        return .send(.delegate(.noteSelected(id)))

                    case .response(.notesLoaded(.success(let notes))):
                        state.notes = notes
                        return .none

                    case .response(.notesLoaded(.failure)):
                        return .none

                    case .response(.noteAdded(.success(let conversation))),
                         .response(.notesDeleted(.success(let conversation))):
                        state.isMutating = false
                        return .merge(
                            .send(.delegate(.conversationUpdated(conversation))),
                            loadNotes(conversationID: state.conversationID),
                            .send(.performNextMutation)
                        )

                    case .response(.noteAdded(.failure)),
                         .response(.notesDeleted(.failure)):
                        state.isMutating = false
                        return .send(.performNextMutation)

                    case .delegate:
                        return .none
                }
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
            .cancellable(id: CancelID.load, cancelInFlight: true)
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
                            }
                        )))

                    case .deletion(let ids):
                        await send(.response(.notesDeleted(
                            TaskResult {
                                try await managingConversationUsecase.deleteNotes(
                                    ids,
                                    conversationID
                                )
                            }
                        )))
                }
            }
        }
    }

}

extension ConversationDetailScreen.Notes.Feature {

    @ObservableState
    struct State: Equatable {
        let conversationID: Conversation.ID
        var notes: [Note] = []
        var noteInput = ""
        var pendingMutations: [Mutation] = []
        var isMutating = false

        enum Mutation: Equatable {
            case addition(String)
            case deletion([Note.ID])
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case load
        case cancel
        case performNextMutation
        case view(View)
        case response(Response)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case noteInputChanged(String)
            case noteAdded
            case notesDeleted(IndexSet)
            case noteSelected(Note.ID)
        }

        @CasePathable
        enum Response {
            case notesLoaded(Result<[Note], DomainError>)
            case noteAdded(TaskResult<Conversation>)
            case notesDeleted(TaskResult<Conversation>)
        }

        @CasePathable
        enum Delegate {
            case noteSelected(Note.ID)
            case conversationUpdated(Conversation)
        }
    }

    private enum CancelID {
        case load
    }

}
