
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.PlaybackPanel {

    @Reducer
    struct Feature {
        @Dependency(\.playingRecordUsecase) private var playingRecordUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .prepare(let fileName, let pins):
                        state.pins = pins
                        return .run { send in
                            await send(.response(.prepared(
                                TaskResult {
                                    try await playingRecordUsecase.prepare(fileName)
                                }
                            )))
                        }
                        .cancellable(id: CancelID.playback, cancelInFlight: true)

                    case .finish:
                        state.isPrepared = false
                        state.isPlaying = false
                        state.currentTime = .zero
                        state.duration = .zero
                        return .merge(
                            .cancel(id: CancelID.playback),
                            .run { _ in await playingRecordUsecase.finish() }
                        )

                    case .view(.playButtonTapped):
                        return .run { _ in await playingRecordUsecase.play() }

                    case .view(.pauseButtonTapped):
                        return .run { _ in await playingRecordUsecase.pause() }

                    case .view(.seekChanged(let time)):
                        return .run { _ in await playingRecordUsecase.seek(time) }

                    case .view(.skipBackwardTapped):
                        let time = state.currentTime - state.skipInterval.timeInterval
                        return .run { _ in await playingRecordUsecase.seek(time) }

                    case .view(.skipForwardTapped):
                        let time = state.currentTime + state.skipInterval.timeInterval
                        return .run { _ in await playingRecordUsecase.seek(time) }

                    case .view(.nextPinTapped):
                        guard let pin = state.pins.sorted().first(
                            where: { $0 > state.currentTime }
                        ) else {
                            return .none
                        }
                        return .run { _ in await playingRecordUsecase.seek(pin) }

                    case .view(.rateChanged(let rate)):
                        return .run { _ in await playingRecordUsecase.changeRate(rate) }

                    case .response(.prepared(.success)):
                        return playbackUpdates()

                    case .response(.prepared(.failure(let error))):
                        let failure: DomainError.PlayingRecordUsecaseFailure = switch error as? DomainError {
                            case .playingRecordUsecase(let failure):
                                failure

                            case .none, .some:
                                .prepareFailed
                        }
                        return .send(.delegate(.failed(failure)))

                    case let .response(.updated(
                        isPrepared,
                        isPlaying,
                        currentTime,
                        duration,
                        rate
                    )):
                        state.isPrepared = isPrepared
                        state.isPlaying = isPlaying
                        state.currentTime = currentTime
                        state.duration = duration
                        state.rate = rate
                        return .none

                    case .delegate:
                        return .none
                }
            }
        }

        private func playbackUpdates() -> Effect<Action> {
            .run { send in
                while !Task.isCancelled {
                    await send(.response(.updated(
                        isPrepared: await playingRecordUsecase.isPrepared(),
                        isPlaying: await playingRecordUsecase.isPlaying(),
                        currentTime: await playingRecordUsecase.currentTime(),
                        duration: await playingRecordUsecase.duration(),
                        rate: await playingRecordUsecase.rate()
                    )))
                    try await Task.sleep(for: .milliseconds(100))
                }
            }
            .cancellable(id: CancelID.playback, cancelInFlight: true)
        }
    }

}

extension ConversationDetailScreen.PlaybackPanel.Feature {

    @ObservableState
    struct State: Equatable {
        @Shared(.appStorage(.skipInterval)) var skipInterval: SkipInterval = .five

        var isPrepared = false
        var isPlaying = false
        var currentTime: TimeInterval = .zero
        var duration: TimeInterval = .zero
        var rate: Float = 1
        var pins: [TimeInterval] = []
    }

    @CasePathable
    enum Action: ViewAction {
        case prepare(fileName: String, pins: [TimeInterval])
        case finish
        case view(View)
        case response(Response)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case playButtonTapped
            case pauseButtonTapped
            case seekChanged(TimeInterval)
            case skipBackwardTapped
            case skipForwardTapped
            case nextPinTapped
            case rateChanged(Float)
        }

        @CasePathable
        enum Response {
            case prepared(TaskResult<Void>)
            case updated(
                isPrepared: Bool,
                isPlaying: Bool,
                currentTime: TimeInterval,
                duration: TimeInterval,
                rate: Float
            )
        }

        @CasePathable
        enum Delegate {
            case failed(DomainError.PlayingRecordUsecaseFailure)
        }
    }

    private enum CancelID {
        case playback
    }

}
