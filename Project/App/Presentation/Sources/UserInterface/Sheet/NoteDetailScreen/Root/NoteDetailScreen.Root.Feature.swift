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

                    case .view(.appeared):
                        let id = state.noteID
                        return .run { send in
                            await send(.response(.noteLoaded(
                                await managingNoteUsecase.note(id)
                            )))
                        }

                    case .view(.saveButtonTapped):
                        guard state.isAbleToSave, var note = state.note else {
                            return .none
                        }
                        note.original = state.original
                        note.translation = state.translation
                        let originalParticleCount = state.original.components(separatedBy: " ").count
                        let translationParticleCount = state.translation.components(separatedBy: " ").count
                        note.category = originalParticleCount > 2 || translationParticleCount > 2
                            ? .sentence
                            : .vocabulary
                        let updatedNote = note
                        state.isSaving = true
                        return .run { send in
                            await send(
                                .response(
                                    .noteUpdated(
                                        await managingNoteUsecase.updateNote(updatedNote)
                                    )
                                )
                            )
                        }

                    case .response(.noteLoaded(.success(let note))):
                        state.setLoaded(note)
                        return .none

                    case .response(.noteLoaded(.failure)):
                        state.noteLoadFailed = true
                        return .none

                    case .response(.noteUpdated(.success)):
                        return .run { _ in
                            await dismiss()
                        }

                    case .response(.noteUpdated(.failure)):
                        state.isSaving = false
                        state.alert = .saveFailed
                        return .none

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
        @Presents var alert: AlertState<Action.Alert>?

        let noteID: Note.ID
        fileprivate var note: Note?
        var noteLoadFailed = false
        var original: String = ""
        var translation: String = ""
        var isSaving: Bool = false

        init(noteID: Note.ID) {
            self.noteID = noteID
        }

        var isVocabulary: Bool? {
            note.map({ $0.category == .vocabulary })
        }

        var isAbleToSave: Bool {
            guard let note else {
                return false
            }
            let isEdited = original != note.original || translation != note.translation
            let isEmpty = original.isEmpty && translation.isEmpty
            return isEdited && !isEmpty && !isSaving
        }

        mutating func setLoaded(_ note: Note?) {
            self.note = note
            noteLoadFailed = note == nil
            original = note?.original ?? ""
            translation = note?.translation ?? ""
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
            case noteLoaded(Result<Note?, DomainError>)
            case noteUpdated(Result<Void, DomainError>)
        }

        @CasePathable
        enum Alert: Equatable {}
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
