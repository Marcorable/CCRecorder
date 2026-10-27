
import Foundation

enum RecorderServiceFailure: Error {
    case permissionDenied
    case prepareFailed
    case notPrepared
}

@MainActor
protocol LegacyRecorderService: AnyObject {
    var isRecording: Bool { get }
    var currentTime: TimeInterval { get }

    func prepare() async throws
    func start()
    func pause()
    func finish() throws -> URL
    func cancel()
}

extension AudioRecorder: LegacyRecorderService {}

#if DEBUG
@MainActor
final class MockRecorderService: LegacyRecorderService {
    var isRecording: Bool
    var currentTime: TimeInterval
    var error: Error?
    var delay: Duration

    private(set) var isCanceled: Bool = false

    init(
        isRecording: Bool = false,
        currentTime: TimeInterval = 12.3,
        error: Error? = nil,
        delay: Duration = .zero
    ) {
        self.isRecording = isRecording
        self.currentTime = currentTime
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
    }
}
#endif
