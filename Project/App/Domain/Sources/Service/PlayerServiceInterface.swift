
import Foundation

@MainActor
public protocol PlayerServiceInterface: AnyObject, Sendable {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var rate: Float { get }

    func prepare(with fileURL: URL) throws
    func play()
    func pause()
    func finish()
    func seek(to time: TimeInterval)
    func changeRate(to value: Float)
}
