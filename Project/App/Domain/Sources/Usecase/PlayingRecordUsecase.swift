
import Foundation

public protocol PlayingRecordUsecase: AnyObject, Sendable {
    var isPlaying: Bool { get async }
    var currentTime: TimeInterval { get async }
    var duration: TimeInterval { get async }
    var rate: Float { get async }

    func prepare(fileName: String) async throws
    func play() async
    func pause() async
    func finish() async
    func seek(to time: TimeInterval) async
    func changeRate(to value: Float) async
}
extension DomainError {

    public enum PlayingRecordUsecaseFailure: Error, Equatable, Sendable {
        case fileNotFound
        case prepareFailed
    }

}

#if DEBUG
public actor FakePlayingRecordUsecase: PlayingRecordUsecase {
    public private(set) var isPlaying: Bool
    public private(set) var currentTime: TimeInterval
    public private(set) var duration: TimeInterval
    public private(set) var rate: Float

    public init(
        isPlaying: Bool = false,
        currentTime: TimeInterval = .zero,
        duration: TimeInterval = .zero,
        rate: Float = 1
    ) {
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.rate = rate
    }

    public func prepare(fileName: String) async throws {}

    public func play() async {
        isPlaying = true
    }

    public func pause() async {
        isPlaying = false
    }

    public func finish() async {
        isPlaying = false
        currentTime = .zero
    }

    public func seek(to time: TimeInterval) async {
        currentTime = time
    }

    public func changeRate(to value: Float) async {
        rate = value
    }
}
#endif
