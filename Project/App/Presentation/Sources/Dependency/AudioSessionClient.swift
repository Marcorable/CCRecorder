
import AVFAudio

import ComposableArchitecture

@DependencyClient
struct AudioSessionClient: Sendable {
    var authorizationStatus: @Sendable () -> Status = { .notDetermined }
    var requestAuthorization: @Sendable () async -> Status = { .denied }
    var activate: @Sendable () throws -> Void
}

extension AudioSessionClient {

    enum Status: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }

}

extension AudioSessionClient: DependencyKey {

    static let liveValue = Self(
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
        }
    )

    static let previewValue = Self()
    static let testValue = Self()

}

extension DependencyValues {

    var audioSession: AudioSessionClient {
        get { self[AudioSessionClient.self] }
        set { self[AudioSessionClient.self] = newValue }
    }

}
