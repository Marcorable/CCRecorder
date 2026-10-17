
import Foundation
import Observation

/// 녹음 화면이 쓰는 녹음 엔진 인터페이스. 구현은 `AudioRecorder`.
@MainActor
protocol AudioRecording: AnyObject {
    var isRecording: Bool { get }
    var currentTime: TimeInterval { get }
    var pins: [TimeInterval] { get }

    func prepare() async throws
    func start()
    func pause()
    func addPin()
    func removePin(at index: Int)
    func finish() throws -> URL
    func cancel()
}

extension AudioRecorder: AudioRecording {}

#if DEBUG
@MainActor
@Observable
final class MockAudioRecording: AudioRecording {
    var isRecording: Bool
    var currentTime: TimeInterval
    var pins: [TimeInterval]
    var error: Error?
    var delay: Duration

    private(set) var isCanceled: Bool = false

    init(
        isRecording: Bool = false,
        currentTime: TimeInterval = 12.3,
        pins: [TimeInterval] = [3.0, 8.5],
        error: Error? = nil,
        delay: Duration = .zero
    ) {
        self.isRecording = isRecording
        self.currentTime = currentTime
        self.pins = pins
        self.error = error
        self.delay = delay
    }

    func prepare() async throws {
        try await Task.sleep(for: delay)
        if let error {
            throw error
        }
    }

    func start() {
        isRecording = true
    }

    func pause() {
        isRecording = false
    }

    func addPin() {
        guard isRecording else { return }

        pins.append(currentTime)
    }

    func removePin(at index: Int) {
        guard pins.indices.contains(index) else { return }

        pins.remove(at: index)
    }

    func finish() throws -> URL {
        if let error {
            throw error
        }
        isRecording = false
        return FileManager.default.temporaryDirectory.appendingPathComponent("mock.m4a")
    }

    func cancel() {
        isRecording = false
        isCanceled = true
        currentTime = .zero
        pins = []
    }
}
#endif
