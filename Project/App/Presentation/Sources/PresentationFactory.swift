
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
        let managingNoteUsecase: @MainActor () -> ManagingNoteUsecase
        let recordingUsecase: @MainActor () -> RecordingUsecase

        public init(
            managingNoteUsecase: @escaping @MainActor () -> ManagingNoteUsecase,
            recordingUsecase: @escaping @MainActor () -> RecordingUsecase
        ) {
            self.managingNoteUsecase = managingNoteUsecase
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
        OnboardScreen.Root()
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
                            NoteDetailScreen.Root.Feature(
                                managingNoteUsecase: dependency.managingNoteUsecase()
                            )
                        }
                    )
                )
                .presentationDetents(note.category.presentationDetents)
        }
    }

}

// 임시
extension PresentationFactory {

    public static var recordScreen: some View {
        RecordScreen.Root(
            store: .init(
                initialState: .init(),
                reducer: {
                    RecordScreen.Root.Feature(
                        recordingUsecase: dependency.recordingUsecase()
                    )
                }
            )
        )
    }

}

private extension Note.Category {

    var presentationDetents: Set<PresentationDetent> {
        switch self {
            case .vocabulary:   [.medium]
            case .sentence:     [.medium, .large]
        }
    }

}
