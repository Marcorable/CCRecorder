
import Foundation

import Domain
import ComposableArchitecture

@DependencyClient
struct RecordingClient: Sendable {
    var isRecording: @Sendable () async -> Bool = { false }
    var currentTime: @Sendable () async -> TimeInterval = { .zero }
    var prepare: @Sendable () async throws -> Void
    var start: @Sendable () async -> Void
    var pause: @Sendable () async -> Void
    var finish: @Sendable (Conversation) async throws -> Void
    var cancel: @Sendable () async -> Void
}

extension RecordingClient {

    init(usecase: RecordingUsecase) {
        self.init(
            isRecording: { await usecase.isRecording },
            currentTime: { await usecase.currentTime },
            prepare: { try await usecase.prepare() },
            start: { await usecase.start() },
            pause: { await usecase.pause() },
            finish: { try await usecase.finish($0) },
            cancel: { await usecase.cancel() }
        )
    }

}

extension RecordingClient: TestDependencyKey {

    static let previewValue = Self(usecase: FakeRecordingUsecase())
    static let testValue = Self()

}

extension DependencyValues {

    var recordingUsecase: RecordingClient {
        get { self[RecordingClient.self] }
        set { self[RecordingClient.self] = newValue }
    }

}
