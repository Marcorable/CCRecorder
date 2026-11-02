
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
                        return .merge(
                            .cancel(id: CancelID.load),
                            .cancel(id: CancelID.mutation)
                        )

                    case .view(.noteInputChanged(let input)):
                        state.noteInput = input
                        return .none

                    case .view(.noteAdded):
                        let input = state.noteInput
                        guard !input.isEmpty else {
                            return .none
                        }
                        state.noteInput = ""
                        let conversationID = state.conversationID
                        return .run { send in
                            await send(.response(.noteAdded(
                                TaskResult {
                                    try await managingConversationUsecase.addNote(
                                        input,
                                        conversationID
                                    )
                                }
                            )))
                        }
                        .cancellable(id: CancelID.mutation, cancelInFlight: true)

                    case .view(.notesDeleted(let offsets)):
                        let ids = offsets.map { state.notes[$0].id }
                        let conversationID = state.conversationID
                        return .run { send in
                            await send(.response(.notesDeleted(
                                TaskResult {
                                    try await managingConversationUsecase.deleteNotes(
                                        ids,
                                        conversationID
                                    )
                                }
                            )))
                        }
                        .cancellable(id: CancelID.mutation, cancelInFlight: true)

                    case .view(.noteSelected(let id)):
                        return .send(.delegate(.noteSelected(id)))

                    case .response(.notesLoaded(.success(let notes))):
                        state.notes = notes
                        return .none

                    case .response(.notesLoaded(.failure)):
                        return .none

                    case .response(.noteAdded(.success(let conversation))),
                         .response(.notesDeleted(.success(let conversation))):
                        return .merge(
                            .send(.delegate(.conversationUpdated(conversation))),
                            loadNotes(conversationID: state.conversationID)
                        )

                    case .response(.noteAdded(.failure)),
                         .response(.notesDeleted(.failure)),
                         .delegate:
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
    }

}

extension ConversationDetailScreen.Notes.Feature {

    @ObservableState
    struct State: Equatable {
        let conversationID: Conversation.ID
        var notes: [Note] = []
        var noteInput = ""
    }

    @CasePathable
    enum Action: ViewAction {
        case load
        case cancel
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
        case mutation
    }

}
