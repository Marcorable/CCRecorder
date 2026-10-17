//
//  RecordRepository.swift
//  Domain
//
//  Created by Yongwoo Marco on 2022/07/04.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Foundation.NSURL

public protocol RecordRepository {
    var newRecordFileURL: URL { get }
	func read(of item: URL) -> Data?
	func delete(from item: URL) throws
}
