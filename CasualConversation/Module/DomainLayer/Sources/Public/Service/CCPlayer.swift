//
//  CCPlayer.swift
//  Domain
//
//  Created by 김용우 on 6/3/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common

import Combine
import Foundation

public protocol CCPlayer {
    var isPlayingSubject: CurrentValueSubject<Bool, Never> { get }
    var timeSubject: CurrentValueSubject<(current: TimeInterval, duration: TimeInterval), Never> { get }
    func stopTrackingCurrentTime()
    func setup(filePath: URL, completion: (CCError?) -> Void)
    func start()
    func pause()
    func finish()
    func seek(to time: Double)
    func changePlayingRate(to value: Float)
    func removeRecordFile(from filePath: URL, completion: (CCError?) -> Void) // FIXME: RecordFile 관리 분리 필요
}
