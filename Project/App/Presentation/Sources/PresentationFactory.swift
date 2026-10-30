
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

    public static var onboardScreen: some View {
        OnboardScreen.Root(
            store: .init(
                initialState: .init(),
                reducer: { OnboardScreen.Root.Feature() }
            )
        )
    }

    public static var forcedUpdateScreen: some View {
        EmptyView() // TODO: 강제 업데이트 화면
    }

    public static var rootStack: some View {
        RootStack()
    }

}

extension PresentationFactory {

    static func make(sheet: Sheet) -> some View {
        switch sheet {
            case .noteDetail(let note):
                NoteDetailScreen.Root(
                    store: .init(
                        initialState: .init(note: note),
                        reducer: {
                            NoteDetailScreen.Root.Feature()
                        },
                        withDependencies: {
                            $0.managingNoteUsecase = .init(usecase: dependency.managingNoteUsecase())
                        }
                    )
                )
                .presentationDetents(note.category.presentationDetents)
        }
    }

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
                        }
                    )
                )

            case .conversationDetail(let conversation):
                ConversationDetailScreen.Root(
                    store: .init(
                        initialState: .init(conversation: conversation),
                        reducer: {
                            ConversationDetailScreen.Root.Feature()
                        },
                        withDependencies: {
                            $0.navigator = navigator
                            $0.managingConversationUsecase = .init(usecase: dependency.managingConversationUsecase())
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
