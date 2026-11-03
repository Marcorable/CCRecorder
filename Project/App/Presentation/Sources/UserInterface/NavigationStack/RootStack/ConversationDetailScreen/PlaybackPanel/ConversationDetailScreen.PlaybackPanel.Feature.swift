
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.PlaybackPanel {

    @Reducer
    struct Feature {
        @Dependency(\.audioSession) private var audioSession
        @Dependency(\.continuousClock) private var clock
        @Dependency(\.playingRecordUsecase) private var playingRecordUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .parent(let action):
                        return reduce(into: &state, action: action)

                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .delegate:
                        return .none
                }
            }
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
        case parent(Parent)
        case view(View)
        case response(Response)
        case delegate(Delegate)

        @CasePathable
        enum Parent {
            case conversationLoaded(
                fileName: String,
                pins: [TimeInterval]
            )
            case conversationDetailDisappeared
        }

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
            case audioSessionUpdates
            case prepared(TaskResult<Void>)
            case playbackStarted(TaskResult<Void>)
            case playbackUpdates
            case audioSessionEvent(AudioSessionClient.Event)
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
            case interrupted
        }
    }

    private enum CancelID {
        case audioSession
        case prepare
        case playbackStart
        case ticker
    }

}

extension ConversationDetailScreen.PlaybackPanel.Feature {

    private func reduce(
        into state: inout State,
        action: Action.Parent
    ) -> Effect<Action> {
        switch action {
            case .conversationLoaded(let fileName, let pins):
                state.pins = pins
                return .concatenate(
                    .merge(
                        .cancel(id: CancelID.prepare),
                        .cancel(id: CancelID.playbackStart),
                        .cancel(id: CancelID.ticker),
                        .cancel(id: CancelID.audioSession)
                    ),
                    .send(.response(.audioSessionUpdates)),
                    .run { send in
                        await send(.response(.prepared(
                            TaskResult {
                                try audioSession.activate()
                                try await playingRecordUsecase.prepare(fileName)
                            }
                        )))
                    }
                    .cancellable(
                        id: CancelID.prepare,
                        cancelInFlight: true
                    )
                )

            case .conversationDetailDisappeared:
                state.isPrepared = false
                state.isPlaying = false
                state.currentTime = .zero
                state.duration = .zero
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.playbackStart),
                    .cancel(id: CancelID.ticker),
                    .cancel(id: CancelID.audioSession),
                    .run { _ in await playingRecordUsecase.finish() }
                )
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .playButtonTapped:
                return .run { send in
                    await send(.response(.playbackStarted(
                        TaskResult {
                            try audioSession.activate()
                            await playingRecordUsecase.play()
                        }
                    )))
                }
                .cancellable(
                    id: CancelID.playbackStart,
                    cancelInFlight: true
                )

            case .pauseButtonTapped:
                state.isPlaying = false
                return .merge(
                    .cancel(id: CancelID.ticker),
                    .run { _ in await playingRecordUsecase.pause() }
                )

            case .seekChanged(let time):
                return .run { _ in await playingRecordUsecase.seek(time) }

            case .skipBackwardTapped:
                let time = state.currentTime - state.skipInterval.timeInterval
                return .run { _ in await playingRecordUsecase.seek(time) }

            case .skipForwardTapped:
                let time = state.currentTime + state.skipInterval.timeInterval
                return .run { _ in await playingRecordUsecase.seek(time) }

            case .nextPinTapped:
                guard let pin = state.pins.sorted().first(
                    where: { $0 > state.currentTime }
                ) else {
                    return .none
                }
                return .run { _ in await playingRecordUsecase.seek(pin) }

            case .rateChanged(let rate):
                return .run { _ in await playingRecordUsecase.changeRate(rate) }
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .prepared(.success):
                return .send(.response(.playbackUpdates))

            case .prepared(.failure(let error)):
                let failure: DomainError.PlayingRecordUsecaseFailure = switch error as? DomainError {
                    case .playingRecordUsecase(let failure):
                        failure

                    case .none, .some:
                        .prepareFailed
                }
                return .merge(
                    .cancel(id: CancelID.audioSession),
                    .send(.delegate(.failed(failure)))
                )

            case .updated(
                let isPrepared,
                let isPlaying,
                let currentTime,
                let duration,
                let rate
            ):
                state.isPrepared = isPrepared
                state.isPlaying = isPlaying
                state.currentTime = currentTime
                state.duration = duration
                state.rate = rate
                return .none

            case .audioSessionEvent(.interruptionBegan):
                state.isPlaying = false
                return .merge(
                    .cancel(id: CancelID.playbackStart),
                    .cancel(id: CancelID.ticker),
                    .run { _ in await playingRecordUsecase.pause() },
                    .send(.delegate(.interrupted))
                )

            case .playbackStarted(.success):
                return .send(.response(.playbackUpdates))

            case .playbackStarted(.failure):
                state.isPlaying = false
                return .send(.delegate(.interrupted))

            case .playbackUpdates:
                return .run { send in
                    while !Task.isCancelled {
                        await send(.response(.updated(
                            isPrepared: await playingRecordUsecase.isPrepared(),
                            isPlaying: await playingRecordUsecase.isPlaying(),
                            currentTime: await playingRecordUsecase.currentTime(),
                            duration: await playingRecordUsecase.duration(),
                            rate: await playingRecordUsecase.rate()
                        )))
                        try await clock.sleep(for: .milliseconds(100))
                    }
                }
                .cancellable(
                    id: CancelID.ticker,
                    cancelInFlight: true
                )

            case .audioSessionUpdates:
                return .run { send in
                    for await event in audioSession.events() {
                        await send(.response(.audioSessionEvent(event)))
                    }
                }
                .cancellable(
                    id: CancelID.audioSession,
                    cancelInFlight: true
                )
        }
    }

}
