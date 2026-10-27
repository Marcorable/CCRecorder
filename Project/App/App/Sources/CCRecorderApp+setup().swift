
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
                managingNoteUsecase: {
                    DomainFactory.makeManagingNoteUsecase(
                        noteRepository: DataFactory.noteRepository(
                            modelContainer: modelContainer
                        )
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
