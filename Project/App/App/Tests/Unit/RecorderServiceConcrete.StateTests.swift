
import Foundation
import Testing

@testable import CCRecorder

@Suite("Recorder Service 상태 관리", .serialized)
@MainActor
struct RecorderServiceConcreteStateTests {
    private let fileURL: URL
    private let service: RecorderServiceConcrete

    init() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recorder-service-\(UUID().uuidString).m4a")
        service = .init()
    }
}

extension RecorderServiceConcreteStateTests {

    @Test("준비하지 않고 완료하면 notPrepared 오류를 던진다")
    func finishWithoutPreparationThrows() {
        // when, then
        #expect(throws: RecorderServiceConcrete.ServiceError.notPrepared) {
            try service.finish()
        }
    }

    @Test("녹음을 취소하면 상태와 시간이 초기화된다")
    func cancellationResetsState() throws {
        defer { cleanUp() }

        // given
        try service.prepare(with: fileURL)

        // when
        service.cancel()

        // then
        #expect(!service.isRecording)
        #expect(service.currentTime == .zero)
        #expect(throws: RecorderServiceConcrete.ServiceError.notPrepared) {
            try service.finish()
        }
    }

    @Test("준비한 녹음을 완료하면 준비한 파일 URL을 반환한다")
    func finishReturnsPreparedFileURL() throws {
        defer { cleanUp() }

        // given
        try service.prepare(with: fileURL)

        // when
        let finishedURL = try service.finish()

        // then
        #expect(finishedURL == fileURL)
        #expect(!service.isRecording)
    }

}

private extension RecorderServiceConcreteStateTests {

    func cleanUp() {
        service.cancel()
        try? FileManager.default.removeItem(at: fileURL)
    }

}
