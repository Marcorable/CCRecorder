
import Foundation

import Domain
import ComposableArchitecture

extension MainScreen.NoteList {

    @Reducer
    struct Feature {
        @Dependency(\.managingNoteUsecase) private var managingNoteUsecase

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

extension MainScreen.NoteList.Feature {

    @ObservableState
    struct State: Equatable {
        var isLoading = false

        fileprivate var notes: [Note]?

        var rows: [NoteBoard.Row.ViewModel]? {
            notes?.sorted(
                by: { lhs, rhs in
                    if lhs.isDone == rhs.isDone {
                        lhs.createdDate < rhs.createdDate
                    } else {
                        !lhs.isDone
                    }
                }
            )
            .map({
                .init(
                    id: $0.id,
                    original: $0.original,
                    translation: $0.translation,
                    isVocabulary: $0.category == .vocabulary
                )
            })
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
            case noteDetailDismissed
        }

        @CasePathable
        enum View {
            case task
            case reload
            case noteTapped(UUID)
            case deleteRequested([UUID])
        }

        @CasePathable
        enum Response {
            case notesLoading
            case notesLoaded(Result<[Note], DomainError>)
            case notesDeleted(
                ids: [Note.ID],
                result: Result<Void, DomainError>
            )
        }

        @CasePathable
        enum Delegate {
            case noteSelected(Note.ID)
            case loadFailed
            case deleteFailed
        }
    }

    private enum CancelID {
        case loadNotes
    }

}

extension MainScreen.NoteList.Feature {

    private func reduce(
        into state: inout State,
        action: Action.Parent
    ) -> Effect<Action> {
        switch action {
            case .noteDetailDismissed:
                state.isLoading = true
                return .send(.response(.notesLoading))
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .task:
                guard state.notes == nil, !state.isLoading else {
                    return .none
                }
                state.isLoading = true
                return .send(.response(.notesLoading))

            case .reload:
                state.isLoading = true
                return .send(.response(.notesLoading))

            case .noteTapped(let id):
                guard state.notes?.contains(where: { $0.id == id }) == true else {
                    return .none
                }
                return .send(.delegate(.noteSelected(id)))

            case .deleteRequested(let ids):
                guard state.rows != nil, !ids.isEmpty else {
                    return .none
                }
                return .run { send in
                    await send(
                        .response(
                            .notesDeleted(
                                ids: ids,
                                result: await managingNoteUsecase.deleteNotes(ids)
                            )
                        )
                    )
                }
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .notesLoading:
                return .run { send in
                    await send(
                        .response(
                            .notesLoaded(await managingNoteUsecase.loadNotes())
                        )
                    )
                }
                .cancellable(
                    id: CancelID.loadNotes,
                    cancelInFlight: true
                )

            case .notesLoaded(.success(let notes)):
                state.isLoading = false
                state.notes = notes
                return .none

            case .notesLoaded(.failure):
                state.isLoading = false
                return .send(.delegate(.loadFailed))

            case .notesDeleted(let ids, .success):
                state.notes?.removeAll(where: { ids.contains($0.id) })
                return .none

            case .notesDeleted(_, .failure):
                return .send(.delegate(.deleteFailed))
        }
    }

}
