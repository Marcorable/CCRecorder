
import AVFAudio
import Foundation
import Testing

import Domain

@testable import CCRecorder

@Suite("Player Service 재생 제어", .serialized)
struct PlayerServiceConcretePlaybackTests {
    private let fileURL: URL
    private let service: PlayerServiceConcrete

    init() throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("player-service-\(UUID().uuidString).caf")
        try Self.makeAudioFile(at: fileURL)
        service = .init()
    }
}

extension PlayerServiceConcretePlaybackTests {

    @Test("파일을 준비하면 재생 길이가 채워진다")
    func preparationUpdatesDuration() async throws {
        // when
        try await service.prepare(with: fileURL)

        // then
        #expect(await service.isPrepared)
        #expect(await service.duration > 0.9)
        #expect(await service.duration < 1.1)
        #expect(await service.currentTime == .zero)
        await cleanUp()
    }

    @Test("시크 위치는 재생 구간 안으로 제한된다")
    func seekClampsToPlaybackRange() async throws {
        // given
        try await service.prepare(with: fileURL)

        // when
        await service.seek(to: -1)

        // then
        #expect(await service.currentTime == .zero)

        // when
        let duration = await service.duration
        await service.seek(to: duration + 1)

        // then
        let currentTime = await service.currentTime
        #expect((.zero...duration).contains(currentTime))
        await cleanUp()
    }

    @Test(
        "배속은 지원 범위 안으로 제한된다",
        arguments: [0.1, 1.5, 3.0]
    )
    func rateClampsToSupportedRange(value: Float) async throws {
        // given
        try await service.prepare(with: fileURL)

        // when
        await service.changeRate(to: value)

        // then
        #expect(await service.rate == min(max(value, 0.5), 2.0))
        await cleanUp()
    }

    @Test("재생을 끝내면 준비 상태와 시간이 초기화된다")
    func finishResetsPlaybackState() async throws {
        // given
        try await service.prepare(with: fileURL)
        await service.seek(to: 0.5)

        // when
        await service.finish()

        // then
        #expect(await !service.isPrepared)
        #expect(await !service.isPlaying)
        #expect(await service.currentTime == .zero)
        #expect(await service.duration == .zero)
        await cleanUp()
    }

    @Test("손상된 파일은 재생 준비에 실패한다")
    func preparationFailsForCorruptedFile() async throws {
        // given
        let corruptedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("player-service-corrupted-\(UUID().uuidString).m4a")
        try Data("not audio".utf8).write(to: corruptedURL)
        defer { try? FileManager.default.removeItem(at: corruptedURL) }

        // when, then
        await #expect(throws: DomainError.PlayerServiceFailure.prepareFailed) {
            try await service.prepare(with: corruptedURL)
        }
    }

}

private extension PlayerServiceConcretePlaybackTests {

    func cleanUp() async {
        await service.finish()
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func makeAudioFile(at fileURL: URL) throws {
        let sampleRate = 44_100.0
        let format = try #require(
            AVAudioFormat(
                standardFormatWithSampleRate: sampleRate,
                channels: 1
            )
        )
        let frameCount = AVAudioFrameCount(sampleRate)
        let buffer = try #require(
            AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
            )
        )
        buffer.frameLength = frameCount

        let file = try AVAudioFile(
            forWriting: fileURL,
            settings: format.settings
        )
        try file.write(from: buffer)
    }

}
