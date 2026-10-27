
#if DEBUG
import Foundation

import Domain

@MainActor
final class RecordingUsecasePreview: RecordingUsecase {
    private(set) var isRecording: Bool
    private(set) var currentTime: TimeInterval

    init(
        isRecording: Bool = false,
        currentTime: TimeInterval = .zero
    ) {
        self.isRecording = isRecording
        self.currentTime = currentTime
    }

    func prepare() async throws {}

    func start() {
        isRecording = true
    }

    func pause() {
        isRecording = false
    }

    func finish(
        _ conversation: Conversation
    ) async throws {}

    func cancel() async {
        isRecording = false
        currentTime = .zero
    }
}
#endif
