//
//  RecordDataController.swift
//  Domain
//
//  Created by Yongwoo Marco on 2022/07/04.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Domain

import Foundation

final class RecordDataController {
    
    private let fileManager: FileManager = .default
    private var directoryURL: URL { dependency.documentURL.appendingPathComponent("Record") }
    
    struct Dependency {
        let documentURL: URL
    }
	private let dependency: Dependency
	
    init(dependency: Dependency) {
		self.dependency = dependency
        
        if fileManager.fileExists(atPath: directoryURL.absoluteString) {
            try? fileManager.createDirectory(atPath: directoryURL.absoluteString, withIntermediateDirectories: true)
        }
	}
	
}

extension RecordDataController: RecordRepository {
		
    var newRecordFileURL: URL {
		let newfileName = Date().formattedForFileName
		let newFileURL = directoryURL
			.appendingPathComponent(newfileName)
			.appendingPathExtension("m4a") // TODO: 녹음파일형식 고민하기 "caf"
		return newFileURL
	}
	
	func read(of item: URL) -> Data? {
        return fileManager.contents(atPath: item.absoluteString)
	}
	
    func delete(from item: URL) throws {
        let filePath = item.absoluteString
        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
        }
	}
	
}
