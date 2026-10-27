
public enum DomainFactory {}

extension DomainFactory {

    public static func makeManagingNoteUsecase(
        repository: any NoteRepository
    ) -> any ManagingNoteUsecase {
        ManagingNoteUsecaseConcrete(
            dependency: .init(noteRepository: repository)
        )
    }

}
