
import Foundation

import ComposableArchitecture

@DependencyClient
struct RecordUsecase {
    var prepare: @MainActor @Sendable () async throws -> State
    var start: @MainActor @Sendable () async -> State = { .idle }
    var pause: @MainActor @Sendable () async -> State = { .idle }
    var state: @MainActor @Sendable () async -> State = { .idle }
    var finish: @MainActor @Sendable () async throws -> URL
    var cancel: @MainActor @Sendable () async -> Void
}

extension RecordUsecase {

    struct State: Equatable, Sendable {
        let isRecording: Bool
        let currentTime: TimeInterval

        static var idle: Self {
            .init(
                isRecording: false,
                currentTime: .zero
            )
        }
    }

    enum Failure: Error, Equatable {
        case permissionDenied
        case prepareFailed
        case finishFailed
    }

}

extension RecordUsecase: TestDependencyKey {

    static let previewValue = Self()
    static let testValue = Self()

}

extension DependencyValues {

    var recordUsecase: RecordUsecase {
        get { self[RecordUsecase.self] }
        set { self[RecordUsecase.self] = newValue }
    }

}

extension RecordUsecase {

    @MainActor
    static func live(service: any LegacyRecorderService) -> Self {
        let state: @MainActor @Sendable () -> State = {
            .init(
                isRecording: service.isRecording,
                currentTime: service.currentTime
            )
        }

        return .init(
            prepare: {
                do {
                    try await service.prepare()
                    return state()
                } catch RecorderServiceFailure.permissionDenied {
                    throw Failure.permissionDenied
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    throw Failure.prepareFailed
                }
            },
            start: {
                service.start()
                return state()
            },
            pause: {
                service.pause()
                return state()
            },
            state: state,
            finish: {
                do {
                    return try service.finish()
                } catch {
                    throw Failure.finishFailed
                }
            },
            cancel: {
                service.cancel()
            }
        )
    }

}
