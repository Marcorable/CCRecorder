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

#if DEBUG
public actor FakeRecordingUsecase: RecordingUsecase {
    public private(set) var isRecording: Bool
    public private(set) var currentTime: TimeInterval

    public init(
        isRecording: Bool = false,
        currentTime: TimeInterval = .zero
    ) {
        self.isRecording = isRecording
        self.currentTime = currentTime
    }

    public func prepare() async throws {}

    public func start() async {
        isRecording = true
    }

    public func pause() async {
        isRecording = false
    }

    public func finish(_ conversation: Conversation) async throws {}

    public func cancel() async {
        isRecording = false
        currentTime = .zero
    }
}
#endif
