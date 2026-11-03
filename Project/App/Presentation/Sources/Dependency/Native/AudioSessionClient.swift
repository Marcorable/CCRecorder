
import AVFAudio

import ComposableArchitecture

@DependencyClient
struct AudioSessionClient: Sendable {
    var authorizationStatus: @Sendable () -> Status = { .notDetermined }
    var requestAuthorization: @Sendable () async -> Status = { .denied }
    var activate: @Sendable () throws -> Void
    var events: @Sendable () -> AsyncStream<Event> = {
        AsyncStream { $0.finish() }
    }
}

extension AudioSessionClient {

    enum Status: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }

    enum Event: Equatable, Sendable {
        case interruptionBegan

        init?(notification: Notification) {
            guard
                let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: rawValue)
            else {
                return nil
            }

            switch type {
                case .began:
                    self = .interruptionBegan

                case .ended:
                    return nil

                @unknown default:
                    return nil
            }
        }
    }

    static let live: Self = .init(
        authorizationStatus: {
            switch AVAudioApplication.shared.recordPermission {
                case .undetermined:
                    return .notDetermined

                case .denied:
                    return .denied

                case .granted:
                    return .authorized

                @unknown default:
                    return .denied
            }
        },
        requestAuthorization: {
            await AVAudioApplication.requestRecordPermission()
            ? .authorized
            : .denied
        },
        activate: {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setActive(true)
        },
        events: {
            AsyncStream { continuation in
                let task = Task {
                    for await notification in NotificationCenter.default.notifications(
                        named: AVAudioSession.interruptionNotification
                    ) {
                        guard let event = Event(notification: notification) else {
                            continue
                        }
                        continuation.yield(event)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    )

    static let preview: Self = .init()

}

extension DependencyValues {

    @DependencyEntry(
        liveValue: AudioSessionClient.live,
        previewValue: AudioSessionClient.preview
    )
    var audioSession: AudioSessionClient = .init()

}
