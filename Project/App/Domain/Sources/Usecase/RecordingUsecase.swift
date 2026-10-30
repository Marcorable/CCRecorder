import Foundation

public protocol RecordingUsecase: AnyObject, Sendable {
    var isRecording: Bool { get async }
    var currentTime: TimeInterval { get async }

    func prepare() async throws
    func start() async
    func pause() async
    func finish(_ conversation: Conversation) async throws
    func cancel() async
}

extension DomainError {

    public enum RecordingUsecaseFailure: Error, Equatable, Sendable {
        case prepareFailed
        case finishFailed
        case saveFailed
    }

}
