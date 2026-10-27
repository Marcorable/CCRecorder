
import Foundation

import Domain
import ComposableArchitecture

extension NoteListScreen.Root {

    @Reducer
    struct Feature {
        let managingNoteUsecase: ManagingNoteUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .view(let action):         reduce(into: &state, action: action)
                    case .response(let action):     reduce(into: &state, action: action)
                    case .noteDetail(let action):   reduce(into: &state, action: action)
                    case .alert(let action):        reduce(into: &state, action: action)
                }
            }
            .ifLet(\.$noteDetail, action: \.noteDetail) {
                NoteDetailScreen.Root.Feature(
                    managingNoteUsecase: managingNoteUsecase
                )
            }
            .ifLet(\.$alert, action: \.alert)
        }

    }

}

extension NoteListScreen.Root.Feature {

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

            case .noteTapped(let id):
                guard let note = state.notes?.first(where: { $0.id == id }) else {
                    return .none
                }
                state.noteDetail = .init(note: note)
                return .none

            case .deleteRequested(let offsets):
                guard let rows = state.rows else {
                    return .none
                }
                let ids = offsets.compactMap { index in
                    rows.indices.contains(index) ? rows[index].id : nil
                }
                guard !ids.isEmpty else {
                    return .none
                }
                return .run { send in
                    await send(
                        .response(
                            .notesDeleted(
                                ids: ids,
                                result: await managingNoteUsecase.deleteNotes(ids: ids)
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
                state.alert = .loadFailed
                return .none

            case .notesDeleted(let ids, .success):
                state.notes?.removeAll { ids.contains($0.id) }
                return .none

            case .notesDeleted(_, .failure):
                state.alert = .deleteFailed
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: PresentationAction<NoteDetailScreen.Root.Feature.Action>
    ) -> Effect<Action> {
        switch action {
            case .dismiss:
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

            case .presented:
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: PresentationAction<Action.Alert>
    ) -> Effect<Action> {
        switch action {
            case .presented(.retryButtonTapped):
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

            case .dismiss:
                return .none
        }
    }

}

private extension NoteListScreen.Root.Feature {

    enum CancelID {
        case loadNotes
    }

}

extension NoteListScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var noteDetail: NoteDetailScreen.Root.Feature.State?

        var notes: [Note]?
        var isLoading = false

        var rows: [NoteList.Row.ViewModel]? {
            notes?.sortedForList.map { note in
                .init(
                    id: note.id,
                    original: note.original,
                    translation: note.translation,
                    isVocabulary: note.category == .vocabulary
                )
            }
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case response(Response)
        case noteDetail(PresentationAction<NoteDetailScreen.Root.Feature.Action>)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case task
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
        enum Alert: Equatable {
            case retryButtonTapped
        }
    }

}

private extension Array where Element == Note {

    var sortedForList: Self {
        sorted { lhs, rhs in
            if lhs.isDone == rhs.isDone {
                lhs.createdDate < rhs.createdDate
            } else {
                !lhs.isDone
            }
        }
    }

}

#if DEBUG
extension NoteListScreen.Root.Feature {

    static var preview: Self {
        .init(
            managingNoteUsecase: FakeManagingNoteUsecase(
                notes: [
                    .init(
                        createdDate: .now,
                        original: "",
                        translation: "테스트 용 문장을 이렇게 작성함",
                        category: .sentence
                    ),
                    .init(
                        createdDate: .now,
                        original: "Test",
                        translation: "",
                        category: .vocabulary
                    )
                ]
            )
        )
    }

}
#endif
