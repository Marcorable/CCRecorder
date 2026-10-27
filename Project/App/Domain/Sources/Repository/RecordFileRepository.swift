
import Foundation

public protocol RecordFileRepository: Sendable {
    func makeRecordingURL() async throws -> URL
    func fileURL(of fileName: String) async -> URL?
    func fileExists(at fileURL: URL) async -> Bool
    func removeFile(at fileURL: URL) async throws
}
