
import Foundation

import Domain

actor RecordFileRepositoryConcrete {
    private static let directoryName: String = "Record"
    private static let fileExtension: String = "m4a"

    private let directoryURL: URL
    private let fileManager: FileManager
    private let now: @Sendable () -> Date

    init(
        fileManager: FileManager = .default,
        baseURL: URL? = nil,
        now: @escaping @Sendable () -> Date = { .init() }
    ) {
        let documentURL = baseURL ?? fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        self.directoryURL = documentURL.appendingPathComponent(
            Self.directoryName,
            isDirectory: true
        )
        self.fileManager = fileManager
        self.now = now
    }
}

extension RecordFileRepositoryConcrete: RecordFileRepository {

    func makeRecordingURL() throws -> URL {
        try prepareDirectory()
        return directoryURL
            .appendingPathComponent(Self.fileName(of: now()))
            .appendingPathExtension(Self.fileExtension)
    }

    func fileURL(of fileName: String) -> URL? {
        guard
            !fileName.isEmpty,
            !fileName.contains("/"),
            fileName != ".",
            fileName != ".."
        else {
            return nil
        }
        return directoryURL.appendingPathComponent(
            fileName,
            isDirectory: false
        )
    }

    func fileExists(at fileURL: URL) -> Bool {
        fileManager.fileExists(
            atPath: fileURL.path(percentEncoded: false)
        )
    }

    func removeFile(at fileURL: URL) throws {
        guard fileExists(at: fileURL) else {
            throw RepositoryError.fileNotFound(fileURL)
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw RepositoryError.removeFailed(error)
        }
    }

}

extension RecordFileRepositoryConcrete {

    enum RepositoryError: Error {
        case directoryCreationFailed(Error)
        case fileNotFound(URL)
        case removeFailed(Error)
    }

}

private extension RecordFileRepositoryConcrete {

    func prepareDirectory() throws {
        guard !fileExists(at: directoryURL) else {
            return
        }

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw RepositoryError.directoryCreationFailed(error)
        }
    }

    static func fileName(of date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

}
