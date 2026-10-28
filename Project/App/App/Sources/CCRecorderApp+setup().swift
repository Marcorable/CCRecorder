
import Data
import Domain
import Presentation

import SwiftData

extension CCRecorderApp {

    func setup() async throws {
        let schema = DataFactory.setup()
        DomainFactory.setup()

        register(
            modelContainer: try .init(
                for: schema,
                configurations: .init(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            )
        )
    }

    func register(modelContainer: ModelContainer) {
        PresentationFactory.register(
            .init(
                managingConversationUsecase: {
                    DomainFactory.makeManagingConversationUsecase(
                        conversationRepository: DataFactory.conversationRepository(
                            modelContainer: modelContainer
                        ),
                        noteRepository: DataFactory.noteRepository(
                            modelContainer: modelContainer
                        ),
                        recordFileRepository: DataFactory.recordFileRepository()
                    )
                },
                managingNoteUsecase: {
                    DomainFactory.makeManagingNoteUsecase(
                        noteRepository: DataFactory.noteRepository(
                            modelContainer: modelContainer
                        )
                    )
                },
                playingRecordUsecase: {
                    DomainFactory.makePlayingRecordUsecase(
                        playerService: PlayerServiceConcrete(),
                        recordFileRepository: DataFactory.recordFileRepository()
                    )
                },
                recordingUsecase: {
                    DomainFactory.makeRecordingUsecase(
                        recorderService: RecorderServiceConcrete(),
                        recordFileRepository: DataFactory.recordFileRepository(),
                        conversationRepository: DataFactory.conversationRepository(
                            modelContainer: modelContainer
                        )
                    )
                }
            )
        )
    }

}
