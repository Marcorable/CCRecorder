
import AVFAudio

import Domain

@MainActor
final class PlayerService: NSObject {
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = .zero
    private(set) var duration: TimeInterval = .zero
    private(set) var rate: Float = 1.0

    private var player: AVAudioPlayer?
    private var ticker: Timer?

    override init() {
        super.init()
    }

    deinit {
        ticker?.invalidate()
    }
}

extension PlayerService {

    enum ServiceError: Error {
        case prepareFailed
    }

}

extension PlayerService: PlayerServiceInterface {

    func prepare(with fileURL: URL) throws {
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.enableRate = true
            player.numberOfLoops = 0
            player.volume = 1.0
            player.rate = rate
            player.delegate = self

            guard player.prepareToPlay() else {
                throw ServiceError.prepareFailed
            }

            finish()
            self.player = player
            self.currentTime = .zero
            self.duration = player.duration
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.prepareFailed
        }
    }

    func play() {
        guard let player, !isPlaying, player.play() else {
            return
        }

        isPlaying = true
        startTicker()
    }

    func pause() {
        guard isPlaying, let player else {
            return
        }

        player.pause()
        updateCurrentTime(with: player)
        isPlaying = false
        stopTicker()
    }

    func finish() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = .zero
        duration = .zero
        stopTicker()
    }

    func seek(to time: TimeInterval) {
        guard let player else {
            return
        }

        stopTicker()
        let seekPosition = min(max(time, .zero), duration)
        player.currentTime = seekPosition
        currentTime = seekPosition

        if isPlaying {
            player.play()
            startTicker()
        }
    }

    func changeRate(to value: Float) {
        let rate = min(max(value, 0.5), 2.0)
        self.rate = rate
        player?.rate = rate
    }

}

private extension PlayerService {

    func startTicker() {
        stopTicker()

        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard
                    let self,
                    self.isPlaying,
                    let player = self.player
                else {
                    return
                }
                self.updateCurrentTime(with: player)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    func updateCurrentTime(with player: AVAudioPlayer) {
        currentTime = player.currentTime
    }

}

extension PlayerService: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            guard self?.player === player else {
                return
            }

            player.currentTime = .zero
            self?.isPlaying = false
            self?.currentTime = .zero
            self?.stopTicker()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard self?.player === player else {
                return
            }

            player.stop()
            self?.isPlaying = false
            self?.updateCurrentTime(with: player)
            self?.stopTicker()
        }
    }

}
