//
//  +setupAVFAudio().swift
//  CCRecorderApp
//
//  Created by 김용우 on 6/3/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import AVFAudio

extension LaunchScreenView {
    
    func setupAVFAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("\(Self.self) \(#function) - setCategory Failure") // FIXME: Error 처리 필요
        }
    }
    
}
