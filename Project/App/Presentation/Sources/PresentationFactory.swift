
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
