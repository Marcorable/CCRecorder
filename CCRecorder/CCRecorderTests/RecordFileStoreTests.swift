
import Testing
import Foundation

@testable import CCRecorder

@Suite("RecordFileStore 파일 관리")
struct RecordFileStoreTests {
    private let baseURL: URL
    private let sut: RecordFileStore

    init() throws {
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )

        sut = .init(baseURL: baseURL)
    }
}

extension RecordFileStoreTests {

    @Test("녹음 디렉토리가 없으면 생성한다")
    func prepareDirectoryCreatesMissingDirectory() throws {
        defer { cleanUp() }

        // given
        #expect(!sut.fileExists(at: sut.directoryURL))

        // when
        try sut.prepareDirectory()

        // then
        #expect(sut.fileExists(at: sut.directoryURL))
    }

    @Test("녹음 디렉토리가 이미 있으면 기존 파일을 보존한다")
    func prepareDirectoryPreservesExistingFile() throws {
        defer { cleanUp() }

        // given
        try sut.prepareDirectory()
        let existing = sut.makeNewFileURL()
        try Data("녹음물".utf8).write(to: existing)

        // when
        try sut.prepareDirectory()

        // then
        #expect(sut.fileExists(at: existing))
    }

    @Test("새 녹음 파일 URL은 초 단위 이름과 m4a 확장자를 가진다")
    func makeNewFileURLUsesTimestampAndM4AExtension() throws {
        defer { cleanUp() }

        // given
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 23
        components.hour = 14
        components.minute = 5
        components.second = 9
        let date = try #require(Calendar.current.date(from: components))

        // when
        let url = sut.makeNewFileURL(at: date)

        // then
        #expect(url.lastPathComponent == "2026-09-23_14-05-09.m4a")
        #expect(url.deletingLastPathComponent() == sut.directoryURL)
    }

    @Test("새 녹음 파일 경로에는 file 스킴이 섞이지 않는다")
    func makeNewFileURLDoesNotContainFileScheme() {
        defer { cleanUp() }

        // when
        let url = sut.makeNewFileURL()

        // then
        #expect(!url.path(percentEncoded: false).contains("file://"))
    }

    @Test("저장된 녹음 파일을 제거한다")
    func removeFileDeletesStoredFile() throws {
        defer { cleanUp() }

        // given
        try sut.prepareDirectory()
        let url = sut.makeNewFileURL()
        try Data("녹음물".utf8).write(to: url)
        #expect(sut.fileExists(at: url))

        // when
        try sut.removeFile(at: url)

        // then
        #expect(!sut.fileExists(at: url))
    }

    @Test("없는 녹음 파일을 제거하면 fileNotFound 오류를 던진다")
    func removeMissingFileThrowsFileNotFound() throws {
        defer { cleanUp() }

        // given
        try sut.prepareDirectory()
        let url = sut.makeNewFileURL()

        // when, then
        #expect {
            try sut.removeFile(at: url)
        } throws: { error in
            guard case RecordFileStore.StoreError.fileNotFound = error else {
                return false
            }
            return true
        }
    }

    @Test("컨테이너 경로가 바뀌어도 파일 이름으로 같은 녹음물을 찾는다")
    func fileURLResolvesAfterContainerMoves() throws {
        defer { cleanUp() }

        // given
        try sut.prepareDirectory()
        let url = sut.makeNewFileURL()
        try Data("녹음물".utf8).write(to: url)
        let fileName = url.lastPathComponent

        let movedBaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: movedBaseURL) }
        try FileManager.default.moveItem(at: baseURL, to: movedBaseURL)
        let movedStore = RecordFileStore(baseURL: movedBaseURL)

        // when
        let resolved = try #require(movedStore.fileURL(of: fileName))

        // then
        #expect(movedStore.fileExists(at: resolved))
        #expect(!sut.fileExists(at: url))
    }

    @Test("빈 이름이나 경로가 포함된 이름으로는 녹음 파일을 찾지 않는다")
    func fileURLRejectsEmptyAndPathNames() {
        defer { cleanUp() }

        // when, then
        #expect(sut.fileURL(of: "") == nil)
        #expect(sut.fileURL(of: ".") == nil)
        #expect(sut.fileURL(of: "..") == nil)
        #expect(sut.fileURL(of: "../other.m4a") == nil)
    }

}

private extension RecordFileStoreTests {

    func cleanUp() {
        try? FileManager.default.removeItem(at: baseURL)
    }

}
