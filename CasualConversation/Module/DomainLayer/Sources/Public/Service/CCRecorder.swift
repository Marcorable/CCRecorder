//
//  CCRecorder.swift
//  Domain
//
//  Created by 김용우 on 6/16/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common

import Combine
import Foundation

public protocol CCRecorder {
    var isRecordingSubject: CurrentValueSubject<Bool, Never> { get }
    var currentTimeSubject: CurrentValueSubject<TimeInterval, Never> { get }
    
    func setup(completion: (CCError?) -> Void)
    func start()
    func pause()
    func stop(completion: (Result<URL, CCError>) -> Void)
    func finish(isCancel: Bool)
}
