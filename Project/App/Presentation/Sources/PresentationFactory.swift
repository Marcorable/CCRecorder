
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

    public static var noteListScreen: some View {
        NoteListScreen.Root(
            store: .init(
                initialState: .init(),
                reducer: {
                    NoteListScreen.Root.Feature(
                        managingNoteUsecase: dependency.managingNoteUsecase()
                    )
                }
            )
        )
    }

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

    public static var settingScreen: some View {
        SettingScreen.Context(
            viewModel: .init(
                model: .init(
                    dependency: .init(bundle: .main)
                )
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
