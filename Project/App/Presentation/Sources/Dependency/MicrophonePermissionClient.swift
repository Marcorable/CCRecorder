
import AVFAudio

import Dependencies
import DependenciesMacros

@DependencyClient
struct MicrophonePermissionClient: Sendable {
    var authorizationStatus: @Sendable () -> Status = { .notDetermined }
    var requestAuthorization: @Sendable () async -> Status = { .denied }
}

extension MicrophonePermissionClient {

    enum Status: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }

}

extension MicrophonePermissionClient: DependencyKey {

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
        }
    )

    static let previewValue = Self()
    static let testValue = Self()

}

extension DependencyValues {

    var microphonePermission: MicrophonePermissionClient {
        get { self[MicrophonePermissionClient.self] }
        set { self[MicrophonePermissionClient.self] = newValue }
    }

}
