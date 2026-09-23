//
//  AudioRecorder.swift
//  CCRecorder
//
//  Created by 김용우 on 9/23/26.
//

import AVFAudio
import Observation

/// AVAudioRecorder 를 감싸 녹음 상태를 관찰 가능한 형태로 노출한다.
@MainActor
@Observable
final class AudioRecorder {

    enum State {
        case idle
        case recording
        case paused
    }

    enum RecordError: Error {
        case permissionDenied
        case prepareFailed
        case notPrepared
    }

    private(set) var state: State = .idle
    private(set) var currentTime: TimeInterval = .zero
    private(set) var pins: [TimeInterval] = []

    var isRecording: Bool { state == .recording }

    @ObservationIgnored private let store: RecordFileStore
    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(store: RecordFileStore = .init()) {
        self.store = store

        observeSessionNotifications()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver(_:))
    }

}

// MARK: - 녹음 제어
extension AudioRecorder {

    /// 권한 확인부터 파일 준비까지 마친다. 녹음 화면 진입 시 호출한다.
    func prepare() async throws {
        guard await AudioSessionController.requestRecordPermission() else {
            throw RecordError.permissionDenied
        }

        try store.prepareDirectory()

        let recorder = try AVAudioRecorder(
            url: store.makeNewFileURL(),
            settings: Self.recordSettings
        )

        guard recorder.prepareToRecord() else {
            throw RecordError.prepareFailed
        }

        self.recorder = recorder
        self.state = .idle
        self.currentTime = .zero
        self.pins = []
    }

    func start() {
        guard let recorder, state != .recording, recorder.record() else { return }

        state = .recording
        startTicker()
    }

    func pause() {
        guard state == .recording, let recorder else { return }

        recorder.pause()
        state = .paused
        stopTicker()
    }

    /// 현재 시점을 북마크한다.
    func addPin() {
        guard state == .recording else { return }

        pins.append(currentTime)
    }

    /// 녹음을 끝내고 저장된 파일 경로를 돌려준다.
    func finish() throws -> URL {
        guard let recorder else {
            throw RecordError.notPrepared
        }

        let filePath = recorder.url
        recorder.stop()
        updateCurrentTime(with: recorder)
        cleanUp()

        return filePath
    }

    /// 녹음을 취소하고 파일을 지운다.
    func cancel() {
        guard let recorder else { return }

        recorder.stop()
        recorder.deleteRecording()
        cleanUp()

        currentTime = .zero
        pins = []
    }

}

// MARK: - 경과 시간
private extension AudioRecorder {

    func startTicker() {
        stopTicker()

        /// 스크롤 중에도 시간이 멈추지 않도록 .common 모드로 등록한다.
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                /// pause() 직후 이미 예약된 콜백이 값을 덮어쓰지 않도록 상태를 확인한다.
                /// AVAudioRecorder.currentTime 은 녹음 중에만 유효하다.
                guard let self, self.state == .recording, let recorder = self.recorder else { return }
                self.updateCurrentTime(with: recorder)
            }
        }
        RunLoop.main.add(timer, forMode: .common)

        ticker = timer
    }

    func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    func updateCurrentTime(with recorder: AVAudioRecorder) {
        currentTime = recorder.currentTime
    }

    func cleanUp() {
        stopTicker()
        recorder = nil
        state = .idle
    }

}

// MARK: - 세션 알림 처리
private extension AudioRecorder {

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

    /// 전화 등으로 세션이 끊기면 녹음을 멈춘다.
    func handleInterruption(_ notification: Notification) {
        guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawValue) else {
            return
        }

        switch type {
            case .began:
                pause()
            case .ended:
                break /// 자동 재개하지 않고 사용자가 직접 이어가도록 둔다
            @unknown default:
                break
        }
    }

    /// 이어폰이 빠지면 주변 소리가 그대로 녹음되므로 멈춘다.
    func handleRouteChange(_ notification: Notification) {
        guard let rawValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue),
              reason == .oldDeviceUnavailable,
              let previousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
              previousRoute.outputs.first?.portType == .headphones else {
            return
        }

        pause()
    }

}

private extension AudioRecorder {

    static var recordSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

}

