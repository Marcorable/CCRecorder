
import Foundation

@MainActor
public protocol RecorderServiceInterface: AnyObject, Sendable {
    var isRecording: Bool { get }
    var currentTime: TimeInterval { get }

    func prepare(with fileURL: URL) throws
    func start()
    func pause()
    func finish() throws -> URL
    func cancel()
}
