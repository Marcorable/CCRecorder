//
//  AuthorizationChecker.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import AVFAudio

enum AuthorizationChecker {
    
    static func recordPermission(completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .denied:
            completion(false)
        case .undetermined:
            session.requestRecordPermission(completion)
        case .granted:
            completion(true)
        @unknown default:
            fatalError("Check AVAudioSession update")
        }
    }
    
}
