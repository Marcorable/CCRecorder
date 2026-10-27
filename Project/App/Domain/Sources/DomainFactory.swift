
public enum DomainFactory {}

extension DomainFactory {

    public static func makeManagingNoteUsecase(
        repository: NoteRepository
    ) -> ManagingNoteUsecase {
        ManagingNoteUsecaseConcrete(
            dependency: .init(noteRepository: repository)
        )
    }

    public static func makeRecordingUsecase(
        recorderService: RecorderServiceInterface,
        recordFileRepository: RecordFileRepository,
        conversationRepository: ConversationRepository
    ) -> RecordingUsecase {
        RecordingUsecaseConcrete(
            dependency: .init(
                recorderService: recorderService,
                recordFileRepository: recordFileRepository,
                conversationRepository: conversationRepository
            )
        )
    }

}
