
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
                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .noteDetailDismissed:
                        return loadNotes(into: &state)

                    case .delegate:
                        return .none
                }
            }
        }
    }

}

extension MainScreen.NoteList.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .task:
                guard state.notes == nil, !state.isLoading else {
                    return .none
                }
                return loadNotes(into: &state)

            case .reload:
                return loadNotes(into: &state)

            case .noteTapped(let id):
                guard state.notes?.contains(where: { $0.id == id }) == true else {
                    return .none
                }
                return .send(.delegate(.noteSelected(id)))

            case .deleteRequested(let offsets):
                guard let rows = state.rows else {
                    return .none
                }
                let ids = offsets.compactMap({ index in
                    rows.indices.contains(index) ? rows[index].id : nil
                })
                guard !ids.isEmpty else {
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

    private func loadNotes(into state: inout State) -> Effect<Action> {
        state.isLoading = true
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
    }

}

extension MainScreen.NoteList.Feature {

    @ObservableState
    struct State: Equatable {
        var notes: [Note]?
        var isLoading = false

        var rows: [MainScreen.NoteList.Row.ViewModel]? {
            notes?.sortedForList.map({ note in
                .init(
                    id: note.id,
                    original: note.original,
                    translation: note.translation,
                    isVocabulary: note.category == .vocabulary
                )
            })
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case response(Response)
        case noteDetailDismissed
        case delegate(Delegate)

        @CasePathable
        enum View {
            case task
            case reload
            case noteTapped(Note.ID)
            case deleteRequested(IndexSet)
        }

        @CasePathable
        enum Response {
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

private extension Array where Element == Note {

    var sortedForList: Self {
        sorted(by: { lhs, rhs in
            if lhs.isDone == rhs.isDone {
                lhs.createdDate < rhs.createdDate
            } else {
                !lhs.isDone
            }
        })
    }

}
