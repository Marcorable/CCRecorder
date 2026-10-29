
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

    public static func register(_ dependency: Dependency) {
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

}

extension PresentationFactory {

    public static func make(sheet: Sheet) -> some View {
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

    public static var rootStack: some View {
        RootStack(
            store: .init(
                initialState: .init(),
                reducer: {
                    RootStack.Feature()
                },
                withDependencies: {
                    $0.managingConversationUsecase = .init(usecase: dependency.managingConversationUsecase())
                    $0.managingNoteUsecase = .init(usecase: dependency.managingNoteUsecase())
                    $0.playingRecordUsecase = .init(usecase: dependency.playingRecordUsecase())
                    $0.recordingUsecase = .init(usecase: dependency.recordingUsecase())
                }
            )
        )
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
