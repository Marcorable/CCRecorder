
import SwiftUI

import Data
import Domain
import Presentation

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        do {
            for serviceType in [
                FirebaseService.self,
                AnalyticsServiceConcrete.self,
                CrashReportingServiceConcrete.self,
                PlayerServiceConcrete.self,
                RecorderServiceConcrete.self
            ] as [Service.Type] {
                guard serviceType.application(application, didFinishLaunchingWithOptions: launchOptions) else {
                    fatalError("Failed to initialize \(serviceType)")
                }
            }
            DomainFactory.setup()
            let persistence = try DataFactory.preparePersistence()
            let modelContainer = persistence.modelContainer
            for diagnostic in persistence.diagnostics {
                print("Persistence: \(diagnostic)")
            }
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
