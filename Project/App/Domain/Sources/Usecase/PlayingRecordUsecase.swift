
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
