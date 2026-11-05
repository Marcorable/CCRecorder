
import Foundation
import Testing

import Domain

@testable import CCRecorder

@Suite("Recorder Service 상태 관리", .serialized)
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
    func finishWithoutPreparationThrows() async {
        // when, then
        await #expect(throws: DomainError.RecorderServiceFailure.notPrepared) {
            try await service.finish()
        }
    }

    @Test("녹음을 취소하면 상태와 시간이 초기화된다")
    func cancellationResetsState() async throws {
        // given
        try await service.prepare(with: fileURL)

        // when
        await service.cancel()

        // then
        #expect(await !service.isRecording)
        #expect(await service.currentTime == .zero)
        await #expect(throws: DomainError.RecorderServiceFailure.notPrepared) {
            try await service.finish()
        }
        await cleanUp()
    }

    @Test("준비한 녹음을 완료하면 준비한 파일 URL을 반환한다")
    func finishReturnsPreparedFileURL() async throws {
        // given
        try await service.prepare(with: fileURL)

        // when
        let finishedURL = try await service.finish()

        // then
        #expect(finishedURL == fileURL)
        #expect(await !service.isRecording)
        await cleanUp()
    }

}

private extension RecorderServiceConcreteStateTests {

    func cleanUp() async {
        await service.cancel()
        try? FileManager.default.removeItem(at: fileURL)
    }

}
