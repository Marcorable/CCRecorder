
import Testing
import AVFAudio
import Foundation

@testable import CCRecorder

@Suite("AudioPlayer 재생 제어", .serialized)
@MainActor
struct AudioPlayerPlaybackTests {
    private let filePath: URL
    private let sut = AudioPlayer()

    init() throws {
        filePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio-player-\(UUID().uuidString).caf")
        try Self.makeAudioFile(at: filePath)
    }
}

extension AudioPlayerPlaybackTests {

    @Test("파일을 준비하면 실제 재생 길이가 채워진다")
    func setupUpdatesDuration() throws {
        // when
        try sut.setup(filePath: filePath)

        // then
        #expect(sut.duration > 0.9)
        #expect(sut.duration < 1.1)
        #expect(sut.currentTime == .zero)
    }

    @Test("준비한 파일을 재생하고 일시정지하면 현재 시간이 유지된다")
    func playAndPauseKeepsCurrentTime() async throws {
        // given
        try sut.setup(filePath: filePath)

        // when
        sut.play()
        try await Task.sleep(for: .milliseconds(250))
        sut.pause()
        let pausedTime = sut.currentTime
        try await Task.sleep(for: .milliseconds(150))

        // then
        #expect(!sut.isPlaying)
        #expect(pausedTime > .zero)
        #expect(sut.currentTime == pausedTime)
    }

    @Test("시크 위치는 재생 구간 안으로 제한된다")
    func seekClampsToPlaybackRange() throws {
        // given
        try sut.setup(filePath: filePath)

        // when
        sut.seek(to: -1)

        // then
        #expect(sut.currentTime == .zero)

        // when
        sut.seek(to: sut.duration + 1)

        // then
        #expect(abs(sut.currentTime - sut.duration) < 0.01)
    }

    @Test(
        "배속은 0.5배에서 2배 사이로 반영된다",
        arguments: [0.1, 1.5, 3.0]
    )
    func rateClampsToSupportedRange(value: Float) throws {
        // given
        try sut.setup(filePath: filePath)

        // when
        sut.changeRate(to: value)

        // then
        #expect(sut.rate == min(max(value, 0.5), 2.0))
    }

    @Test("손상된 파일은 재생 준비에서 실패한다")
    func setupThrowsForCorruptedFile() throws {
        // given
        let corruptedFilePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio-player-corrupted-\(UUID().uuidString).m4a")
        try Data("not audio".utf8).write(to: corruptedFilePath)
        defer { try? FileManager.default.removeItem(at: corruptedFilePath) }

        // when, then
        #expect(throws: (any Error).self) {
            try sut.setup(filePath: corruptedFilePath)
        }
        #expect(sut.duration == .zero)
    }

    @Test("재생을 끝내면 준비 상태와 시간이 초기화된다")
    func finishResetsPlaybackState() throws {
        // given
        try sut.setup(filePath: filePath)
        sut.seek(to: 0.5)

        // when
        sut.finish()

        // then
        #expect(!sut.isPlaying)
        #expect(sut.currentTime == .zero)
        #expect(sut.duration == .zero)
        sut.play()
        #expect(!sut.isPlaying)
    }

    @Test("인터럽션이 시작되면 재생을 일시정지한다")
    func interruptionPausesPlayback() async throws {
        // given
        try sut.setup(filePath: filePath)
        sut.play()

        // when
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
            ]
        )
        await Task.yield()

        // then
        #expect(!sut.isPlaying)
    }

}

private extension AudioPlayerPlaybackTests {

    static func makeAudioFile(at filePath: URL) throws {
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
            forWriting: filePath,
            settings: format.settings
        )
        try file.write(from: buffer)
    }

}
