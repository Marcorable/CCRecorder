
import Foundation

public protocol RecorderService: AnyObject, Sendable {
    var isRecording: Bool { get async }
    var currentTime: TimeInterval { get async }

    func prepare(with fileURL: URL) async throws(DomainError.RecorderServiceFailure)
    func start() async
    func pause() async
    func finish() async throws(DomainError.RecorderServiceFailure) -> URL
    func cancel() async
}

extension DomainError {

    public enum RecorderServiceFailure: Error, Equatable, Sendable {
        case prepareFailed
        case notPrepared
    }

}
