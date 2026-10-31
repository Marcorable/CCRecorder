
import SwiftUI

import Domain

typealias Asset = PresentationAsset
typealias Factory = PresentationFactory

@MainActor
public enum PresentationFactory {
    static var dependency: Dependency!
}

extension PresentationFactory {

    public struct Dependency {
        let managingConversationUsecase: @MainActor () -> ManagingConversationUsecase
        let managingNoteUsecase: @MainActor () -> ManagingNoteUsecase
        let playingRecordUsecase: @MainActor () -> PlayingRecordUsecase
        let recordingUsecase: @MainActor () -> RecordingUsecase

        public init(
            managingConversationUsecase: @escaping @MainActor () -> ManagingConversationUsecase,
            managingNoteUsecase: @escaping @MainActor () -> ManagingNoteUsecase,
            playingRecordUsecase: @escaping @MainActor () -> PlayingRecordUsecase,
            recordingUsecase: @escaping @MainActor () -> RecordingUsecase
        ) {
            self.managingConversationUsecase = managingConversationUsecase
            self.managingNoteUsecase = managingNoteUsecase
            self.playingRecordUsecase = playingRecordUsecase
            self.recordingUsecase = recordingUsecase
        }
    }

    public static func setup(_ dependency: Dependency) {
        self.dependency = dependency
    }

}

extension PresentationFactory {

    public static var launchScreen: some View {
        LaunchScreen.Root()
    }

    public static var forcedUpdateScreen: some View {
        EmptyView() // TODO: 강제 업데이트 화면
    }

    public static var rootStack: some View {
        RootStack()
    }

}

extension PresentationFactory {

    @ViewBuilder
    static func make(
        by route: RootStack.Route,
        with navigator: RootStack.Client
    ) -> some View {
        switch route {
            case .main:
                MainScreen.Root(
                    store: .init(
                        initialState: .init(),
                        reducer: {
                            MainScreen.Root.Feature()
                        },
                        withDependencies: {
                            $0.navigator = navigator
                            $0.managingConversationUsecase = .init(usecase: dependency.managingConversationUsecase())
                            $0.managingNoteUsecase = .init(usecase: dependency.managingNoteUsecase())
                            $0.recordingUsecase = .init(usecase: dependency.recordingUsecase())
                        }
                    )
                )

            case .conversationDetail(let id):
                ConversationDetailScreen.Root(
                    store: .init(
                        initialState: .init(conversationID: id),
                        reducer: {
                            ConversationDetailScreen.Root.Feature()
                        },
                        withDependencies: {
                            $0.navigator = navigator
                            $0.managingConversationUsecase = .init(usecase: dependency.managingConversationUsecase())
                            $0.managingNoteUsecase = .init(usecase: dependency.managingNoteUsecase())
                            $0.playingRecordUsecase = .init(usecase: dependency.playingRecordUsecase())
                        }
                    )
                )

            case .setting:
                SettingScreen.Root(
                    store: .init(
                        initialState: .init(),
                        reducer: {
                            SettingScreen.Root.Feature()
                        },
                        withDependencies: {
                            $0.navigator = navigator
                        }
                    )
                )
        }
    }

}

extension Note.Category {

    var presentationDetents: Set<PresentationDetent> {
        switch self {
            case .vocabulary:   [.medium]
            case .sentence:     [.medium, .large]
        }
    }

}
