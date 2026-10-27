
import SwiftUI

import Domain

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
