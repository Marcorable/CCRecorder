
import Testing
import AVFAudio
import Foundation

@testable import CCRecorder

/// 실제 마이크 입력이 필요하므로 권한이 없는 환경에서는 건너뛴다.
/// 시뮬레이터에서는 `xcrun simctl privacy <device> grant microphone <bundleId>` 로 권한을 줄 수 있다.
@Suite(
    "AudioRecorder 녹음 제어",
    .serialized,
    .enabled(
        if: AudioSessionController.recordPermission == .granted,
        "마이크 권한이 필요한 테스트입니다"
    )
)
@MainActor
struct AudioRecorderTests {
    private let baseURL: URL
    private let store: RecordFileStore
    private let sut: AudioRecorder

    init() throws {
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )

        try AudioSessionController.configure()

        store = .init(baseURL: baseURL)
        sut = .init(store: store)
    }
}

extension AudioRecorderTests {

    @Test("녹음을 끝내면 녹음물이 파일로 저장된다")
    func finishSavesRecordingFile() async throws {
        defer { cleanUp() }

        // given
        try await sut.prepare()
        sut.start()
        #expect(sut.isRecording)
        try await Task.sleep(for: .milliseconds(600))

        // when
        let filePath = try sut.finish()

        // then
        #expect(!sut.isRecording)
        #expect(store.fileExists(at: filePath))
        #expect(try fileSize(of: filePath) > 0)
    }

    @Test("녹음을 취소하면 녹음물과 상태가 초기화된다")
    func cancelDeletesRecording() async throws {
        defer { cleanUp() }

        // given
        try await sut.prepare()
        sut.start()
        try await Task.sleep(for: .milliseconds(300))

        // when
        sut.cancel()

        // then
        #expect(!sut.isRecording)
        #expect(sut.currentTime == .zero)
        #expect(sut.pins.isEmpty)
    }

    @Test("녹음을 일시정지하면 경과 시간이 유지된다")
    func pauseKeepsElapsedTime() async throws {
        defer { cleanUp() }

        // given
        try await sut.prepare()
        sut.start()
        try await Task.sleep(for: .milliseconds(400))

        // when
        sut.pause()
        let pausedTime = sut.currentTime
        try await Task.sleep(for: .milliseconds(300))

        // then
        #expect(sut.state == .paused)
        #expect(sut.currentTime == pausedTime)
    }

    @Test("핀은 녹음 중에만 추가된다")
    func addPinOnlyWhileRecording() async throws {
        defer { cleanUp() }

        // given
        try await sut.prepare()

        // when
        sut.addPin()

        // then
        #expect(sut.pins.isEmpty)

        // when
        sut.start()
        try await Task.sleep(for: .milliseconds(300))
        sut.addPin()

        // then
        #expect(sut.pins.count == 1)
        #expect(try #require(sut.pins.first) > 0)
        sut.cancel()
    }

    @Test("지정한 핀만 제거된다")
    func removePinAtIndex() async throws {
        defer { cleanUp() }

        // given
        try await sut.prepare()
        sut.start()
        try await Task.sleep(for: .milliseconds(200))
        sut.addPin()
        try await Task.sleep(for: .milliseconds(200))
        sut.addPin()
        let secondPin = try #require(sut.pins.last)

        // when
        sut.removePin(at: 0)
        sut.removePin(at: 5)

        // then
        #expect(sut.pins == [secondPin])
        sut.cancel()
    }

    @Test("준비하지 않고 녹음을 끝내면 notPrepared 오류를 던진다")
    func finishWithoutPrepareThrowsNotPrepared() {
        defer { cleanUp() }

        // when, then
        #expect {
            try sut.finish()
        } throws: { error in
            guard case AudioRecorder.RecordError.notPrepared = error else {
                return false
            }
            return true
        }
    }

}

private extension AudioRecorderTests {

    func cleanUp() {
        try? FileManager.default.removeItem(at: baseURL)
    }

    func fileSize(of url: URL) throws -> Int {
        let attributes = try FileManager.default
            .attributesOfItem(atPath: url.path(percentEncoded: false))
        return attributes[.size] as? Int ?? 0
    }

}
