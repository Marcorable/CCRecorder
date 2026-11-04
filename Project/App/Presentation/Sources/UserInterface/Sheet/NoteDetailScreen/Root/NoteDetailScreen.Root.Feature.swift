
import Foundation

import Domain
import ComposableArchitecture

extension NoteDetailScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.dismiss) private var dismiss
        @Dependency(\.managingNoteUsecase) private var managingNoteUsecase

        var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    case .binding:
                        return .none

                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .alert:
                        return .none
                }
            }
            .ifLet(\.$alert, action: \.alert)
        }
    }

}

extension NoteDetailScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        let noteID: Note.ID
        var original = ""
        var translation = ""
        var isLoading = true

        init(noteID: Note.ID) {
            self.noteID = noteID
        }

        @Presents var alert: AlertState<Action.Alert>?

        fileprivate var note: Note?

        var isVocabulary: Bool? {
            note.map({ $0.category == .vocabulary })
        }

        var isAbleToSave: Bool {
            guard let note else {
                return false
            }
            let isEdited = original != note.original || translation != note.translation
            let isEmpty = original.isEmpty && translation.isEmpty
            return isEdited && !isEmpty && !isLoading
        }
    }

    @CasePathable
    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case view(View)
        case response(Response)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case appeared
            case saveButtonTapped
        }

        @CasePathable
        enum Response {
            case noteLoading
            case noteLoaded(Result<Note?, DomainError>)
            case noteUpdating(Note)
            case noteUpdated(Result<Void, DomainError>)
        }

        @CasePathable
        enum Alert: Equatable {}
    }

}

extension NoteDetailScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .appeared:
                state.isLoading = true
                return .send(.response(.noteLoading))

            case .saveButtonTapped:
                guard state.isAbleToSave, var note = state.note else {
                    return .none
                }
                note.original = state.original
                note.translation = state.translation
                let isSentence = [state.original, state.translation]
                    .contains(where: { $0.components(separatedBy: " ").count > 2 })
                note.category = isSentence
                    ? .sentence
                    : .vocabulary
                state.isLoading = true
                return .send(.response(.noteUpdating(note)))
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .noteLoading:
                let id = state.noteID
                return .run { send in
                    await send(.response(.noteLoaded(
                        await managingNoteUsecase.note(id)
                    )))
                }

            case .noteLoaded(.success(let note)):
                state.isLoading = false
                state.note = note
                state.original = note?.original ?? ""
                state.translation = note?.translation ?? ""
                return .none

            case .noteLoaded(.failure):
                state.isLoading = false
                return .none

            case .noteUpdating(let note):
                return .run { send in
                    await send(.response(.noteUpdated(
                        await managingNoteUsecase.updateNote(note)
                    )))
                }

            case .noteUpdated(.success):
                state.isLoading = false
                return .run { _ in
                    await dismiss()
                }

            case .noteUpdated(.failure):
                state.isLoading = false
                state.alert = .saveFailed
                return .none
        }
    }

}

extension AlertState where Action == NoteDetailScreen.Root.Feature.Action.Alert {

    static var saveFailed: Self {
        .init(
            title: {
                TextState("노트 저장 실패")
            },
            actions: {
                ButtonState(role: .cancel) {
                    TextState("확인")
                }
            },
            message: {
                TextState("잠시 후 다시 시도해 주세요")
            }
        )
    }

}
