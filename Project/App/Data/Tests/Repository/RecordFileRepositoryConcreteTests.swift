
import Testing
import Foundation

@testable import Data

extension DataRepositoryTests {

    @Suite("녹음 파일 저장소")
    struct RecordFileRepositoryConcreteTests {
        private let baseURL: URL
        private let repository: RecordFileRepositoryConcrete

        init() throws {
            let baseURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    UUID().uuidString,
                    isDirectory: true
                )
            try FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true
            )

            self.baseURL = baseURL
            self.repository = .init(
                baseURL: baseURL,
                now: {
                    Date(timeIntervalSince1970: 1_798_000_509)
                }
            )
        }
    }

}

extension DataRepositoryTests.RecordFileRepositoryConcreteTests {

    @Test("새 녹음 파일 URL을 생성하며 디렉토리를 준비한다")
    func makeRecordingURLPreparesDirectory() async throws {
        defer { cleanUp() }

        // when
        let fileURL = try await repository.makeRecordingURL()

        // then
        #expect(fileURL.pathExtension == "m4a")
        #expect(
            FileManager.default.fileExists(
                atPath: fileURL.deletingLastPathComponent().path()
            )
        )
    }

    @Test("파일 이름으로 녹음 파일 URL을 복원한다")
    func fileURLResolvesFileName() async throws {
        defer { cleanUp() }

        // given
        let createdURL = try await repository.makeRecordingURL()

        // when
        let resolvedURL = await repository.fileURL(
            of: createdURL.lastPathComponent
        )

        // then
        #expect(resolvedURL == createdURL)
    }

    @Test("저장된 녹음 파일을 제거한다")
    func removeFileDeletesRecording() async throws {
        defer { cleanUp() }

        // given
        let fileURL = try await repository.makeRecordingURL()
        try Foundation.Data("recording".utf8).write(to: fileURL)

        // when
        try await repository.removeFile(at: fileURL)

        // then
        #expect(!FileManager.default.fileExists(atPath: fileURL.path()))
    }

}

private extension DataRepositoryTests.RecordFileRepositoryConcreteTests {

    func cleanUp() {
        try? FileManager.default.removeItem(at: baseURL)
    }

}
