import XCTest
@testable import CCRecorder

final class RecordFileStoreTests: XCTestCase {

    private var baseURL: URL!
    private var sut: RecordFileStore!

    override func setUpWithError() throws {
        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        sut = RecordFileStore(baseURL: baseURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: baseURL)

        baseURL = nil
        sut = nil
    }

    func test_prepareDirectory_디렉토리가_없으면_생성한다() throws {
        XCTAssertFalse(sut.fileExists(at: sut.directoryURL))

        try sut.prepareDirectory()

        XCTAssertTrue(sut.fileExists(at: sut.directoryURL))
    }

    func test_prepareDirectory_이미_있으면_기존_파일을_보존한다() throws {
        try sut.prepareDirectory()
        let existing = sut.makeNewFileURL()
        try Data("녹음물".utf8).write(to: existing)

        try sut.prepareDirectory()

        XCTAssertTrue(sut.fileExists(at: existing))
    }

    func test_makeNewFileURL_초단위_이름과_m4a_확장자를_가진다() {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 23
        components.hour = 14
        components.minute = 5
        components.second = 9
        let date = Calendar.current.date(from: components)!

        let url = sut.makeNewFileURL(at: date)

        XCTAssertEqual(url.lastPathComponent, "2026-09-23_14-05-09.m4a")
        XCTAssertEqual(url.deletingLastPathComponent(), sut.directoryURL)
    }

    func test_makeNewFileURL_경로에_file_스킴이_섞이지_않는다() {
        let url = sut.makeNewFileURL()

        XCTAssertFalse(url.path(percentEncoded: false).contains("file://"))
    }

    func test_removeFile_저장된_파일을_지운다() throws {
        try sut.prepareDirectory()
        let url = sut.makeNewFileURL()
        try Data("녹음물".utf8).write(to: url)
        XCTAssertTrue(sut.fileExists(at: url))

        try sut.removeFile(at: url)

        XCTAssertFalse(sut.fileExists(at: url))
    }

    func test_removeFile_없는_파일이면_fileNotFound_를_던진다() throws {
        try sut.prepareDirectory()
        let url = sut.makeNewFileURL()

        XCTAssertThrowsError(try sut.removeFile(at: url)) { error in
            guard case RecordFileStore.StoreError.fileNotFound = error else {
                return XCTFail("기대한 에러가 아님: \(error)")
            }
        }
    }

    func test_fileURL_컨테이너_경로가_바뀌어도_같은_파일_이름으로_찾는다() throws {
        try sut.prepareDirectory()
        let url = sut.makeNewFileURL()
        try Data("녹음물".utf8).write(to: url)
        let fileName = url.lastPathComponent

        let movedBaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: movedBaseURL) }
        try FileManager.default.moveItem(at: baseURL, to: movedBaseURL)
        let movedStore = RecordFileStore(baseURL: movedBaseURL)

        let resolved = try XCTUnwrap(movedStore.fileURL(of: fileName))
        XCTAssertTrue(movedStore.fileExists(at: resolved))
        XCTAssertFalse(sut.fileExists(at: url))
    }

    func test_fileURL_빈_이름이나_경로가_섞인_이름이면_nil_이다() {
        XCTAssertNil(sut.fileURL(of: ""))
        XCTAssertNil(sut.fileURL(of: "."))
        XCTAssertNil(sut.fileURL(of: ".."))
        XCTAssertNil(sut.fileURL(of: "../other.m4a"))
    }

}
