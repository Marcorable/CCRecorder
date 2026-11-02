
import Testing
import Foundation

@testable import Domain

@Suite("Conversation 녹음")
@MainActor
struct RecordingUsecaseTests {
    private let recorderService: RecorderServiceSpy
    private let fileRepository: RecordFileRepositorySpy
    private let conversationRepository: ConversationRepositorySpy
    private let usecase: RecordingUsecaseConcrete

    init() {
        let recorderService = RecorderServiceSpy()
        let fileRepository = RecordFileRepositorySpy()
        let conversationRepository = ConversationRepositorySpy()
        self.recorderService = recorderService
        self.fileRepository = fileRepository
        self.conversationRepository = conversationRepository
        self.usecase = .init(
            dependency: .init(
                recorderService: recorderService,
                recordFileRepository: fileRepository,
                conversationRepository: conversationRepository
            )
        )
    }
}

extension RecordingUsecaseTests {

    @Test("녹음 파일 URL로 Recorder를 준비한다")
    func prepareUsesRecordingURL() async throws {
        // when
        try await usecase.prepare()

        // then
        #expect(recorderService.preparedFileURL == fileRepository.recordingURL)
    }

    @Test("Recorder 준비에 실패하면 생성한 파일을 정리한다")
    func prepareFailureCleansUpFile() async {
        // given
        recorderService.prepareError = .failed

        // when
        do {
            try await usecase.prepare()
            Issue.record("prepareFailed 오류를 던져야 합니다.")
        } catch DomainError.recordingUsecase(let failure) {
            // then
            #expect(failure == .prepareFailed)
            #expect(recorderService.cancelCallCount == 1)
            #expect(await fileRepository.removedURLs == [fileRepository.recordingURL])
        } catch {
            Issue.record("예상하지 못한 오류입니다: \(error)")
        }
    }

    @Test("녹음을 완료하면 파일 이름을 포함한 Conversation을 저장한다")
    func finishSavesConversation() async throws {
        // given
        try await usecase.prepare()
        let conversation = makeConversation()

        // when
        try await usecase.finish(conversation)

        // then
        let saved = try #require(await conversationRepository.createdConversation)
        #expect(saved.id == conversation.id)
        #expect(saved.recordFileName == "record.m4a")
    }

    @Test("저장에 실패하면 녹음 파일을 제거한다")
    func saveFailureRemovesRecording() async {
        // given
        await conversationRepository.setError(.failed)

        // when
        do {
            try await usecase.finish(makeConversation())
            Issue.record("saveFailed 오류를 던져야 합니다.")
        } catch DomainError.recordingUsecase(let failure) {
            // then
            #expect(failure == .saveFailed)
            #expect(await fileRepository.removedURLs == [fileRepository.recordingURL])
        } catch {
            Issue.record("예상하지 못한 오류입니다: \(error)")
        }
    }

    @Test("녹음을 취소하면 Recorder와 준비된 파일을 정리한다")
    func cancelCleansUpRecorderAndFile() async throws {
        // given
        try await usecase.prepare()

        // when
        await usecase.cancel()

        // then
        #expect(recorderService.cancelCallCount == 1)
        #expect(await fileRepository.removedURLs == [fileRepository.recordingURL])
    }

}

private extension RecordingUsecaseTests {

    func makeConversation() -> Conversation {
        .init(
            createdDate: .init(),
            pins: [],
            title: "Title",
            topic: "",
            parties: []
        )
    }

    enum TestError: Error {
        case failed
    }

    @MainActor
    final class RecorderServiceSpy: RecorderService {
        var isRecording = false
        var currentTime: TimeInterval = .zero
        var prepareError: TestError?
        private(set) var preparedFileURL: URL?
        private(set) var cancelCallCount = 0

        func prepare(with fileURL: URL) throws {
            if let prepareError {
                throw prepareError
            }
            preparedFileURL = fileURL
        }

        func start() {
            isRecording = true
        }

        func pause() {
            isRecording = false
        }

        func finish() throws -> URL {
            .init(filePath: "/tmp/record.m4a")
        }

        func cancel() {
            cancelCallCount += 1
        }
    }

    actor RecordFileRepositorySpy: RecordFileRepository {
        let recordingURL = URL(filePath: "/tmp/record.m4a")
        private(set) var removedURLs: [URL] = []

        func makeRecordingURL() -> URL {
            recordingURL
        }

        func fileURL(of fileName: String) -> URL? {
            recordingURL
        }

        func fileExists(at fileURL: URL) -> Bool {
            true
        }

        func removeFile(at fileURL: URL) {
            removedURLs.append(fileURL)
        }
    }

    actor ConversationRepositorySpy: ConversationRepository {
        private(set) var createdConversation: Conversation?
        private var error: TestError?

        func create(_ conversation: Conversation) throws {
            if let error {
                throw error
            }
            createdConversation = conversation
        }

        func read() throws -> [Conversation] { [] }
        func read(id: Conversation.ID) throws -> Conversation? { nil }
        func update(_ conversation: Conversation) throws {}
        func delete(ids: [UUID]) throws {}

        func setError(_ error: TestError) {
            self.error = error
        }
    }

}
