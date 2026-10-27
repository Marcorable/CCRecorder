
public enum DomainFactory {
    @MainActor private weak static var managingNoteUsecase: ManagingNoteUsecaseConcrete?
    @MainActor private weak static var recordingUsecase: RecordingUsecaseConcrete?
}

extension DomainFactory {

    public static func setup() {}

}

extension DomainFactory {

    @MainActor
    public static func makeManagingNoteUsecase(
        noteRepository: NoteRepository
    ) -> ManagingNoteUsecase {
        if let usecase = managingNoteUsecase {
            return usecase
        } else {
            let usecase = ManagingNoteUsecaseConcrete(
                dependency: .init(
                    noteRepository: noteRepository
                )
            )
            managingNoteUsecase = usecase
            return usecase
        }
    }

    @MainActor
    public static func makeRecordingUsecase(
        recorderService: RecorderService,
        recordFileRepository: RecordFileRepository,
        conversationRepository: ConversationRepository
    ) -> RecordingUsecase {
        if let usecase = recordingUsecase {
            return usecase
        } else {
            let usecase = RecordingUsecaseConcrete(
                dependency: .init(
                    recorderService: recorderService,
                    recordFileRepository: recordFileRepository,
                    conversationRepository: conversationRepository
                )
            )
            recordingUsecase = usecase
            return usecase
        }
    }

}
