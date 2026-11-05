
import Testing
import Foundation

@testable import Domain

@Suite("녹음 재생")
@MainActor
struct PlayingRecordUsecaseTests {
    private let playerService: PlayerServiceSpy
    private let recordFileRepository: RecordFileRepositorySpy
    private let usecase: PlayingRecordUsecaseConcrete

    init() {
        let playerService = PlayerServiceSpy()
        let recordFileRepository = RecordFileRepositorySpy()
        self.playerService = playerService
        self.recordFileRepository = recordFileRepository
        self.usecase = .init(
            dependency: .init(
                playerService: playerService,
                recordFileRepository: recordFileRepository
            )
        )
    }
}

extension PlayingRecordUsecaseTests {

    @Test("존재하는 녹음 파일로 Player를 준비한다")
    func prepareUsesResolvedFileURL() async throws {
        // given
        let fileURL = URL(filePath: "/tmp/record.m4a")
        await recordFileRepository.setFileURL(fileURL)
        await recordFileRepository.setFileExists(true)

        // when
        try await usecase.prepare(fileName: "record.m4a")

        // then
        #expect(playerService.preparedFileURL == fileURL)
    }

    @Test("녹음 파일이 없으면 fileNotFound 오류를 던진다")
    func prepareThrowsFileNotFound() async {
        // when
        do {
            try await usecase.prepare(fileName: "missing.m4a")
            Issue.record("fileNotFound 오류를 던져야 합니다.")
        } catch DomainError.playingRecordUsecase(let failure) {
            // then
            #expect(failure == .fileNotFound)
        } catch {
            Issue.record("예상하지 못한 오류입니다: \(error)")
        }
    }

    @Test("Player 준비에 실패하면 Player를 종료한다")
    func prepareFailureFinishesPlayer() async {
        // given
        await recordFileRepository.setFileURL(.init(filePath: "/tmp/record.m4a"))
        await recordFileRepository.setFileExists(true)
        playerService.error = .prepareFailed

        // when
        do {
            try await usecase.prepare(fileName: "record.m4a")
            Issue.record("prepareFailed 오류를 던져야 합니다.")
        } catch DomainError.playingRecordUsecase(let failure) {
            // then
            #expect(failure == .prepareFailed)
            #expect(playerService.finishCallCount == 1)
        } catch {
            Issue.record("예상하지 못한 오류입니다: \(error)")
        }
    }

    @Test("재생 제어를 Player에 전달한다")
    func playbackCommandsForwardToPlayer() async {
        // when
        await usecase.play()
        await usecase.seek(to: 3)
        await usecase.changeRate(to: 1.5)
        await usecase.pause()
        await usecase.finish()

        // then
        #expect(playerService.playCallCount == 1)
        #expect(playerService.seekTime == 3)
        #expect(playerService.rate == 1.5)
        #expect(playerService.pauseCallCount == 1)
        #expect(playerService.finishCallCount == 1)
    }

}

private extension PlayingRecordUsecaseTests {

    @MainActor
    final class PlayerServiceSpy: PlayerService {
        var isPrepared = false
        var isPlaying = false
        var currentTime: TimeInterval = .zero
        var duration: TimeInterval = .zero
        var rate: Float = 1

        var error: DomainError.PlayerServiceFailure?
        private(set) var preparedFileURL: URL?
        private(set) var playCallCount = 0
        private(set) var pauseCallCount = 0
        private(set) var finishCallCount = 0
        private(set) var seekTime: TimeInterval?

        func prepare(with fileURL: URL) async throws(DomainError.PlayerServiceFailure) {
            if let error {
                throw error
            }
            preparedFileURL = fileURL
        }

        func play() async {
            playCallCount += 1
        }

        func pause() async {
            pauseCallCount += 1
        }

        func finish() async {
            finishCallCount += 1
        }

        func seek(to time: TimeInterval) async {
            seekTime = time
        }

        func changeRate(to value: Float) async {
            rate = value
        }
    }

    actor RecordFileRepositorySpy: RecordFileRepository {
        private var resolvedFileURL: URL?
        private var exists = false

        func makeRecordingURL() throws -> URL {
            .init(filePath: "/tmp/new.m4a")
        }

        func fileURL(of fileName: String) -> URL? {
            resolvedFileURL
        }

        func fileExists(at fileURL: URL) -> Bool {
            exists
        }

        func removeFile(at fileURL: URL) throws {}

        func setFileURL(_ fileURL: URL) {
            resolvedFileURL = fileURL
        }

        func setFileExists(_ exists: Bool) {
            self.exists = exists
        }
    }

}
