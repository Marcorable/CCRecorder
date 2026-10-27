import AVFAudio

@MainActor
final class AudioRecorder {

    enum State {
        case idle
        case recording
        case paused
    }

    private(set) var state: State = .idle
    private var pausedTime: TimeInterval = .zero

    var isRecording: Bool { state == .recording }
    var currentTime: TimeInterval {
        guard state == .recording, let recorder else {
            return pausedTime
        }
        return recorder.currentTime
    }

    private let store: RecordFileStore
    private let requestRecordPermission: @MainActor () async -> Bool
    private var recorder: AVAudioRecorder?
    private var observers: [NSObjectProtocol] = []

    init(
        store: RecordFileStore = .init(),
        requestRecordPermission: @escaping @MainActor () async -> Bool = {
            await AudioSessionController.requestRecordPermission()
        }
    ) {
        self.store = store
        self.requestRecordPermission = requestRecordPermission

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
        try Task.checkCancellation()
        let isGranted = await requestRecordPermission()
        try Task.checkCancellation()

        guard isGranted else {
            throw RecorderServiceFailure.permissionDenied
        }

        try store.prepareDirectory()
        try Task.checkCancellation()

        let fileURL = store.makeNewFileURL()
        var preparedRecorder: AVAudioRecorder?

        do {
            let recorder = try AVAudioRecorder(
                url: fileURL,
                settings: Self.recordSettings
            )
            preparedRecorder = recorder
            try Task.checkCancellation()

            guard recorder.prepareToRecord() else {
                throw RecorderServiceFailure.prepareFailed
            }
            try Task.checkCancellation()

            self.recorder = recorder
            self.state = .idle
            self.pausedTime = .zero
        } catch {
            preparedRecorder?.stop()
            _ = preparedRecorder?.deleteRecording()
            try? store.removeFile(at: fileURL)
            throw error
        }
    }

    func start() {
        guard let recorder, state != .recording, recorder.record() else {
            return
        }

        state = .recording
    }

    func pause() {
        guard state == .recording, let recorder else {
            return
        }

        pausedTime = recorder.currentTime
        recorder.pause()
        state = .paused
    }

    /// 녹음을 끝내고 저장된 파일 경로를 돌려준다.
    func finish() throws -> URL {
        guard let recorder else {
            throw RecorderServiceFailure.notPrepared
        }

        let filePath = recorder.url
        pausedTime = recorder.currentTime
        recorder.stop()
        cleanUp()

        return filePath
    }

    /// 녹음을 취소하고 파일을 지운다.
    func cancel() {
        if let recorder {
            recorder.stop()
            recorder.deleteRecording()
        }

        cleanUp()
        pausedTime = .zero
    }

}

private extension AudioRecorder {

    func cleanUp() {
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
