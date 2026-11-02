
import Data
import Domain
import Presentation

import SwiftUI
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        do {
            for serviceType in [
                PlayerServiceConcrete.self,
                RecorderServiceConcrete.self
            ] as [Service.Type] {
                guard serviceType.application(application, didFinishLaunchingWithOptions: launchOptions) else {
                    fatalError("Failed to initialize \(serviceType)")
                }
            }
            let schema = DataFactory.setup()
            DomainFactory.setup()
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: .init(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            )
            PresentationFactory.setup(
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
        } catch {
            fatalError("Failed to initialize application: \(error)")
        }

        return true
    }

}
