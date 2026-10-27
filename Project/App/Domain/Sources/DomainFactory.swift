

import Foundation

public enum DomainFactory {
    @MainActor private weak static var managingConversationUsecase: ManagingConversationUsecaseConcrete?
    @MainActor private weak static var managingNoteUsecase: ManagingNoteUsecaseConcrete?
    @MainActor private weak static var playingRecordUsecase: PlayingRecordUsecaseConcrete?
    @MainActor private weak static var recordingUsecase: RecordingUsecaseConcrete?
}

extension DomainFactory {

    public static func setup() {}

}

extension DomainFactory {

    @MainActor
    public static func makeManagingConversationUsecase(
        conversationRepository: ConversationRepository,
        noteRepository: NoteRepository,
        now: @escaping @Sendable () -> Date = { .init() }
    ) -> ManagingConversationUsecase {
        if let usecase = managingConversationUsecase {
            return usecase
        } else {
            let usecase = ManagingConversationUsecaseConcrete(
                dependency: .init(
                    conversationRepository: conversationRepository,
                    noteRepository: noteRepository,
                    now: now
                )
            )
            managingConversationUsecase = usecase
            return usecase
        }
    }

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
    public static func makePlayingRecordUsecase(
        playerService: PlayerService,
        recordFileRepository: RecordFileRepository
    ) -> PlayingRecordUsecase {
        if let usecase = playingRecordUsecase {
            return usecase
        } else {
            let usecase = PlayingRecordUsecaseConcrete(
                dependency: .init(
                    playerService: playerService,
                    recordFileRepository: recordFileRepository
                )
            )
            playingRecordUsecase = usecase
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
