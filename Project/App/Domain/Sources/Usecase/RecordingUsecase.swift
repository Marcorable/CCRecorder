import Foundation

@MainActor
public protocol RecordingUsecase: AnyObject, Sendable {
    var isRecording: Bool { get }
    var currentTime: TimeInterval { get }

    func prepare() async throws
    func start()
    func pause()
    func finish(_ conversation: Conversation) async throws
    func cancel() async
}
