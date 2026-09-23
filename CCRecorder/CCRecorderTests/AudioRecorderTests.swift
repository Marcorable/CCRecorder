//
//  AudioRecorderTests.swift
//  CCRecorderTests
//
//  Created by 김용우 on 9/23/26.
//

import XCTest
@testable import CCRecorder

/// 실제 마이크 입력이 필요하므로 권한이 없는 환경에서는 건너뛴다.
/// 시뮬레이터에서는 `xcrun simctl privacy <device> grant microphone <bundleId>` 로 권한을 줄 수 있다.
@MainActor
final class AudioRecorderTests: XCTestCase {

    private var baseURL: URL!
    private var store: RecordFileStore!
    private var sut: AudioRecorder!

    override func setUpWithError() throws {
        try XCTSkipUnless(
            AudioSessionController.recordPermission == .granted,
            "마이크 권한이 필요한 테스트입니다"
        )

        baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        try AudioSessionController.configure()

        store = RecordFileStore(baseURL: baseURL)
        sut = AudioRecorder(store: store)
    }

    override func tearDownWithError() throws {
        if let baseURL {
            try? FileManager.default.removeItem(at: baseURL)
        }

        baseURL = nil
        store = nil
        sut = nil
    }

    func test_finish_녹음물이_파일로_저장된다() async throws {
        try await sut.prepare()
        sut.start()
        XCTAssertTrue(sut.isRecording)

        try await Task.sleep(for: .milliseconds(600))
        let filePath = try sut.finish()

        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(store.fileExists(at: filePath))
        XCTAssertGreaterThan(try fileSize(of: filePath), 0)
    }

    func test_cancel_녹음물이_삭제된다() async throws {
        try await sut.prepare()
        sut.start()
        try await Task.sleep(for: .milliseconds(300))

        sut.cancel()

        XCTAssertFalse(sut.isRecording)
        XCTAssertEqual(sut.currentTime, .zero)
        XCTAssertTrue(sut.pins.isEmpty)
    }

    func test_pause_경과시간이_유지된다() async throws {
        try await sut.prepare()
        sut.start()
        try await Task.sleep(for: .milliseconds(400))

        sut.pause()
        let pausedTime = sut.currentTime
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertEqual(sut.state, .paused)
        XCTAssertEqual(sut.currentTime, pausedTime)
    }

    func test_addPin_녹음중에만_적립된다() async throws {
        try await sut.prepare()

        sut.addPin()
        XCTAssertTrue(sut.pins.isEmpty, "녹음 전에는 핀이 쌓이지 않아야 한다")

        sut.start()
        try await Task.sleep(for: .milliseconds(300))
        sut.addPin()

        XCTAssertEqual(sut.pins.count, 1)
        XCTAssertGreaterThan(sut.pins[0], 0)

        sut.cancel()
    }

    func test_prepare_없이_finish_하면_notPrepared_를_던진다() {
        XCTAssertThrowsError(try sut.finish()) { error in
            guard case AudioRecorder.RecordError.notPrepared = error else {
                return XCTFail("기대한 에러가 아님: \(error)")
            }
        }
    }

}

private extension AudioRecorderTests {

    func fileSize(of url: URL) throws -> Int {
        let attributes = try FileManager.default
            .attributesOfItem(atPath: url.path(percentEncoded: false))
        return attributes[.size] as? Int ?? 0
    }

}
