//
//  AudioSessionController.swift
//  CCRecorder
//
//  Created by 김용우 on 9/23/26.
//

import AVFAudio

/// 앱 전역 오디오 세션 설정과 마이크 권한을 담당한다.
enum AudioSessionController {

    enum SessionError: Error {
        case configurationFailed(Error)
    }

    /// 녹음과 재생을 모두 사용하므로 .playAndRecord 로 설정한다.
    static func configure() throws {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try session.setActive(true)
        } catch {
            throw SessionError.configurationFailed(error)
        }
    }

    static var recordPermission: AVAudioApplication.recordPermission {
        AVAudioApplication.shared.recordPermission
    }

    static func requestRecordPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

}
