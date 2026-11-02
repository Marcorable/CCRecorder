
import AVFAudio
import Foundation

import Domain

actor PlayerServiceConcrete {
    private var player: AVAudioPlayer?
    private var delegate: Delegate?

    var isPrepared: Bool { player != nil }
    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? .zero }
    var duration: TimeInterval { player?.duration ?? .zero }
    var rate: Float { player?.rate ?? 1 }
}

extension PlayerServiceConcrete: Service {

}

extension PlayerServiceConcrete: PlayerService {

    func prepare(with fileURL: URL) throws(DomainError.PlayerServiceFailure) {
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.enableRate = true
            player.numberOfLoops = 0
            player.volume = 1
            player.rate = 1

            let id = UUID()
            let delegate = Delegate(
                id: id,
                finish: { [weak self] in
                    Task { await self?.didFinish(id: id) }
                },
                fail: { [weak self] in
                    Task { await self?.didFail(id: id) }
                }
            )
            player.delegate = delegate

            guard player.prepareToPlay() else {
                throw DomainError.PlayerServiceFailure.prepareFailed
            }

            finish()
            self.player = player
            self.delegate = delegate
        } catch let error as DomainError.PlayerServiceFailure {
            throw error
        } catch {
            throw DomainError.PlayerServiceFailure.prepareFailed
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func finish() {
        player?.stop()
        player = nil
        delegate = nil
    }

    func seek(to time: TimeInterval) {
        guard let player else {
            return
        }
        player.currentTime = min(
            max(time, .zero),
            player.duration
        )
    }

    func changeRate(to value: Float) {
        player?.rate = min(
            max(value, 0.5),
            2
        )
    }

}

private extension PlayerServiceConcrete {

    func didFinish(id: UUID) {
        guard delegate?.id == id else {
            return
        }
        player?.currentTime = .zero
    }

    func didFail(id: UUID) {
        guard delegate?.id == id else {
            return
        }
        player?.stop()
        player = nil
        delegate = nil
    }

}

private extension PlayerServiceConcrete {

    final class Delegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
        let id: UUID
        private let finish: @Sendable () -> Void
        private let fail: @Sendable () -> Void

        nonisolated init(
            id: UUID,
            finish: @escaping @Sendable () -> Void,
            fail: @escaping @Sendable () -> Void
        ) {
            self.id = id
            self.finish = finish
            self.fail = fail
        }

        func audioPlayerDidFinishPlaying(
            _ player: AVAudioPlayer,
            successfully flag: Bool
        ) {
            finish()
        }

        func audioPlayerDecodeErrorDidOccur(
            _ player: AVAudioPlayer,
            error: Error?
        ) {
            fail()
        }
    }

}
