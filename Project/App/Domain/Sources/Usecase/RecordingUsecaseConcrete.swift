
import Foundation

actor RecordingUsecaseConcrete {
    private let dependency: Dependency
    private var recordingFileURL: URL?

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

extension RecordingUsecaseConcrete {

    struct Dependency: Sendable {
        let recorderService: RecorderService
        let recordFileRepository: RecordFileRepository
        let conversationRepository: ConversationRepository
    }

}

extension RecordingUsecaseConcrete: RecordingUsecase {

    var isRecording: Bool {
        get async {
            await dependency.recorderService.isRecording
        }
    }

    var currentTime: TimeInterval {
        get async {
            await dependency.recorderService.currentTime
        }
    }

    func prepare() async throws {
        var fileURL: URL?
        do {
            let preparedFileURL = try await dependency.recordFileRepository.makeRecordingURL()
            fileURL = preparedFileURL

            try Task.checkCancellation()
            try await dependency.recorderService.prepare(with: preparedFileURL)
            try Task.checkCancellation()

            self.recordingFileURL = preparedFileURL
        } catch is CancellationError {
            await dependency.recorderService.cancel()
            if let fileURL {
                try? await dependency.recordFileRepository.removeFile(at: fileURL)
            }
            throw CancellationError()
        } catch {
            await dependency.recorderService.cancel()
            if let fileURL {
                try? await dependency.recordFileRepository.removeFile(at: fileURL)
            }
            throw DomainError.recordingUsecase(.prepareFailed)
        }
    }

    func start() async {
        await dependency.recorderService.start()
    }

    func pause() async {
        await dependency.recorderService.pause()
    }

    func finish(_ conversation: Conversation) async throws {
        let fileURL: URL
        do {
            fileURL = try await dependency.recorderService.finish()
        } catch {
            await cleanUpRecordingFile()
            throw DomainError.recordingUsecase(.finishFailed)
        }

        var conversation = conversation
        conversation.recordFileName = fileURL.lastPathComponent

        do {
            try await dependency.conversationRepository.create(conversation)
            try Task.checkCancellation()
            recordingFileURL = nil
        } catch {
            if error is CancellationError {
                try? await dependency.conversationRepository.delete(ids: [conversation.id])
            }

            try? await dependency.recordFileRepository.removeFile(at: fileURL)
            recordingFileURL = nil
            if error is CancellationError {
                throw CancellationError()
            }
            throw DomainError.recordingUsecase(.saveFailed)
        }
    }

    func cancel() async {
        await dependency.recorderService.cancel()
        await cleanUpRecordingFile()
    }

}

private extension RecordingUsecaseConcrete {

    func cleanUpRecordingFile() async {
        guard let recordingFileURL else {
            return
        }
        try? await dependency.recordFileRepository.removeFile(at: recordingFileURL)
        self.recordingFileURL = nil
    }

}
