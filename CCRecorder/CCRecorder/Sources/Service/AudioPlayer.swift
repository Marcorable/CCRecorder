
import AVFAudio
import Observation

@MainActor
@Observable
final class AudioPlayer: NSObject {
    enum PlaybackError: Error {
        case prepareFailed
    }

    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = .zero
    private(set) var duration: TimeInterval = .zero
    private(set) var rate: Float = 1.0

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()

        observeSessionNotifications()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver(_:))
    }
}

extension AudioPlayer {

    func setup(filePath: URL) throws {
        let player = try AVAudioPlayer(contentsOf: filePath)
        player.enableRate = true
        player.numberOfLoops = 0
        player.volume = 1.0
        player.rate = rate
        player.delegate = self

        guard player.prepareToPlay() else {
            throw PlaybackError.prepareFailed
        }

        finish()
        self.player = player
        self.currentTime = .zero
        self.duration = player.duration
    }

    func play() {
        guard let player else {
            return
        }
        guard !isPlaying else {
            return
        }
        guard player.play() else {
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

    func stopTrackingCurrentTime() {
        stopTicker()
    }

}

private extension AudioPlayer {

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

private extension AudioPlayer {

    func observeSessionNotifications() {
        let center = NotificationCenter.default

        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor [weak self] in
                    self?.handleInterruption(notification)
                }
            }
        )

        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor [weak self] in
                    self?.handleRouteChange(notification)
                }
            }
        )
    }

    func handleInterruption(_ notification: Notification) {
        guard
            let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawValue)
        else {
            return
        }

        switch type {
            case .began:
                pause()

            case .ended:
                break

            @unknown default:
                break
        }
    }

    func handleRouteChange(_ notification: Notification) {
        guard
            let rawValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue),
            reason == .oldDeviceUnavailable,
            let previousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
            previousRoute.outputs.first?.portType == .headphones
        else {
            return
        }

        pause()
    }

}

extension AudioPlayer: AVAudioPlayerDelegate {

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

}
