
import Foundation

public protocol PlayerService: AnyObject, Sendable {
    var isPrepared: Bool { get async }
    var isPlaying: Bool { get async }
    var currentTime: TimeInterval { get async }
    var duration: TimeInterval { get async }
    var rate: Float { get async }

    func prepare(with fileURL: URL) async throws(DomainError.PlayerServiceFailure)
    func play() async
    func pause() async
    func finish() async
    func seek(to time: TimeInterval) async
    func changeRate(to value: Float) async
}

extension DomainError {

    public enum PlayerServiceFailure: Error, Equatable, Sendable {
        case prepareFailed
    }

}
