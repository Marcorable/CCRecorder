
import AVFAudio
import Foundation
import Testing

@testable import CCRecorder

@Suite("Player Service 재생 제어", .serialized)
@MainActor
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
    func preparationUpdatesDuration() throws {
        defer { cleanUp() }

        // when
        try service.prepare(with: fileURL)

        // then
        #expect(service.duration > 0.9)
        #expect(service.duration < 1.1)
        #expect(service.currentTime == .zero)
    }

    @Test("시크 위치는 재생 구간 안으로 제한된다")
    func seekClampsToPlaybackRange() throws {
        defer { cleanUp() }

        // given
        try service.prepare(with: fileURL)

        // when
        service.seek(to: -1)

        // then
        #expect(service.currentTime == .zero)

        // when
        service.seek(to: service.duration + 1)

        // then
        #expect(abs(service.currentTime - service.duration) < 0.01)
    }

    @Test(
        "배속은 지원 범위 안으로 제한된다",
        arguments: [0.1, 1.5, 3.0]
    )
    func rateClampsToSupportedRange(value: Float) throws {
        defer { cleanUp() }

        // given
        try service.prepare(with: fileURL)

        // when
        service.changeRate(to: value)

        // then
        #expect(service.rate == min(max(value, 0.5), 2.0))
    }

    @Test("재생을 끝내면 준비 상태와 시간이 초기화된다")
    func finishResetsPlaybackState() throws {
        defer { cleanUp() }

        // given
        try service.prepare(with: fileURL)
        service.seek(to: 0.5)

        // when
        service.finish()

        // then
        #expect(!service.isPlaying)
        #expect(service.currentTime == .zero)
        #expect(service.duration == .zero)
    }

    @Test("손상된 파일은 재생 준비에 실패한다")
    func preparationFailsForCorruptedFile() throws {
        // given
        let corruptedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("player-service-corrupted-\(UUID().uuidString).m4a")
        try Data("not audio".utf8).write(to: corruptedURL)
        defer { try? FileManager.default.removeItem(at: corruptedURL) }

        // when, then
        #expect(throws: PlayerServiceConcrete.ServiceError.prepareFailed) {
            try service.prepare(with: corruptedURL)
        }
    }

}

private extension PlayerServiceConcretePlaybackTests {

    func cleanUp() {
        service.finish()
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
