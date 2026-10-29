
import Foundation

import Domain
import ComposableArchitecture

@DependencyClient
struct PlayingRecordClient: Sendable {
    var isPlaying: @Sendable () async -> Bool = { false }
    var currentTime: @Sendable () async -> TimeInterval = { .zero }
    var duration: @Sendable () async -> TimeInterval = { .zero }
    var rate: @Sendable () async -> Float = { 1 }
    var prepare: @Sendable (String) async throws -> Void
    var play: @Sendable () async -> Void
    var pause: @Sendable () async -> Void
    var finish: @Sendable () async -> Void
    var seek: @Sendable (TimeInterval) async -> Void
    var changeRate: @Sendable (Float) async -> Void
}

extension PlayingRecordClient {

    init(usecase: PlayingRecordUsecase) {
        self.init(
            isPlaying: { await usecase.isPlaying },
            currentTime: { await usecase.currentTime },
            duration: { await usecase.duration },
            rate: { await usecase.rate },
            prepare: { try await usecase.prepare(fileName: $0) },
            play: { await usecase.play() },
            pause: { await usecase.pause() },
            finish: { await usecase.finish() },
            seek: { await usecase.seek(to: $0) },
            changeRate: { await usecase.changeRate(to: $0) }
        )
    }

}

extension PlayingRecordClient: TestDependencyKey {

    static let previewValue = Self(usecase: FakePlayingRecordUsecase())
    static let testValue = Self()

}

extension DependencyValues {

    var playingRecordUsecase: PlayingRecordClient {
        get { self[PlayingRecordClient.self] }
        set { self[PlayingRecordClient.self] = newValue }
    }

}
