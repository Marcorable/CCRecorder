//
//  RecordFileStore.swift
//  CCRecorder
//
//  Created by 김용우 on 9/23/26.
//

import Foundation

/// 녹음 파일의 저장 위치를 관리한다.
struct RecordFileStore {

    enum StoreError: Error {
        case directoryCreationFailed(Error)
        case fileNotFound(URL)
        case removeFailed(Error)
    }

    static let directoryName: String = "Record"
    static let fileExtension: String = "m4a"

    let directoryURL: URL

    private let fileManager: FileManager

    init(
        fileManager: FileManager = .default,
        baseURL: URL? = nil
    ) {
        let documentURL = baseURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        self.fileManager = fileManager
        self.directoryURL = documentURL.appendingPathComponent(Self.directoryName, isDirectory: true)
    }

}

extension RecordFileStore {

    /// 녹음 디렉토리가 없을 때만 생성한다.
    func prepareDirectory() throws {
        guard !fileExists(at: directoryURL) else { return }

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            throw StoreError.directoryCreationFailed(error)
        }
    }

    func makeNewFileURL(at date: Date = .init()) -> URL {
        directoryURL
            .appendingPathComponent(Self.fileName(of: date))
            .appendingPathExtension(Self.fileExtension)
    }

    func fileExists(at url: URL) -> Bool {
        /// URL 을 경로로 쓸 때 absoluteString 은 `file://` 스킴이 붙어 FileManager 가 찾지 못한다.
        fileManager.fileExists(atPath: url.path(percentEncoded: false))
    }

    func removeFile(at url: URL) throws {
        guard fileExists(at: url) else {
            throw StoreError.fileNotFound(url)
        }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw StoreError.removeFailed(error)
        }
    }

}

private extension RecordFileStore {

    /// 연달아 녹음해도 파일명이 겹치지 않도록 초 단위까지 사용한다.
    static func fileName(of date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

}
