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

                    case .view(.saveButtonTapped):
                        guard state.isAbleToSave else {
                            return .none
                        }
                        state.isSaving = true
                        let note = state.noteForSaving
                        return .run { send in
                            await send(
                                .response(
                                    .noteUpdated(
                                        await managingNoteUsecase.updateNote(note)
                                    )
                                )
                            )
                        }

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

        let note: Note
        var original: String
        var translation: String
        var isSaving: Bool = false

        init(note: Note) {
            self.note = note
            self.original = note.original
            self.translation = note.translation
        }

        var isAbleToSave: Bool {
            let isEdited = original != note.original || translation != note.translation
            let isEmpty = original.isEmpty && translation.isEmpty
            return isEdited && !isEmpty && !isSaving
        }

        var noteForSaving: Note {
            var note = note
            note.original = original
            note.translation = translation
            note.category = category
            return note
        }

        private var category: Note.Category {
            let originalParticleCount = original.components(separatedBy: " ").count
            let translationParticleCount = translation.components(separatedBy: " ").count
            return originalParticleCount > 2 || translationParticleCount > 2
                ? .sentence
                : .vocabulary
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
            case saveButtonTapped
        }

        @CasePathable
        enum Response {
            case noteUpdated(Result<Void, DomainError>)
        }

        @CasePathable
        enum Alert: Equatable {}
    }

}

extension AlertState where Action == NoteDetailScreen.Root.Feature.Action.Alert {

    static var saveFailed: Self {
        Self {
            TextState("노트 저장 실패")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        } message: {
            TextState("잠시 후 다시 시도해 주세요")
        }
    }

}

#if DEBUG
extension NoteDetailScreen.Root.Feature {

    @MainActor
    static var preview: Self {
        .init()
    }

}
#endif
