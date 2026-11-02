
import Foundation

actor PlayingRecordUsecaseConcrete {
    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}
extension PlayingRecordUsecaseConcrete {

    struct Dependency: Sendable {
        let playerService: PlayerService
        let recordFileRepository: RecordFileRepository
    }

}

extension PlayingRecordUsecaseConcrete: PlayingRecordUsecase {

    var isPlaying: Bool {
        get async {
            await dependency.playerService.isPlaying
        }
    }

    var currentTime: TimeInterval {
        get async {
            await dependency.playerService.currentTime
        }
    }

    var duration: TimeInterval {
        get async {
            await dependency.playerService.duration
        }
    }

    var rate: Float {
        get async {
            await dependency.playerService.rate
        }
    }

    func prepare(fileName: String) async throws {
        guard
            let fileURL = await dependency.recordFileRepository.fileURL(of: fileName),
            await dependency.recordFileRepository.fileExists(at: fileURL)
        else {
            throw DomainError.playingRecordUsecase(.fileNotFound)
        }

        do {
            try Task.checkCancellation()
            try await dependency.playerService.prepare(with: fileURL)
            try Task.checkCancellation()
        } catch is CancellationError {
            await dependency.playerService.finish()
            throw CancellationError()
        } catch {
            await dependency.playerService.finish()
            throw DomainError.playingRecordUsecase(.prepareFailed)
        }
    }

    func play() async {
        await dependency.playerService.play()
    }

    func pause() async {
        await dependency.playerService.pause()
    }

    func finish() async {
        await dependency.playerService.finish()
    }

    func seek(to time: TimeInterval) async {
        await dependency.playerService.seek(to: time)
    }

    func changeRate(to value: Float) async {
        await dependency.playerService.changeRate(to: value)
    }

}
