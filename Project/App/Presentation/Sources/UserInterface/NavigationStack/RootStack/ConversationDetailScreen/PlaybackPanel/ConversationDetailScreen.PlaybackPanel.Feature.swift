
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

    typealias Speed = ConversationDetailScreen.PlaybackPanel.Speed

    @ObservableState
    struct State: Equatable {
        @Shared(.appStorage(.skipInterval)) var skipInterval: SkipInterval = .five

        var isPrepared = false
        var isPlaying = false
        var currentTime: TimeInterval = .zero
        var duration: TimeInterval = .zero
        var speed: Speed = .default
        var pins: [TimeInterval] = []

        var isPlaybackDisabled: Bool { !isPrepared }
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
            case speedChanged(Speed)
        }

        @CasePathable
        enum Response {
            case audioSessionUpdates
            case prepared(TaskResult<Void>)
            case playbackStarted(TaskResult<Void>)
            case playbackUpdates
            case audioSessionEvent(AudioSessionClient.Event)
            case seekStarted(TimeInterval)
            case seekCompleted(TimeInterval)
            case rateChangeStarted(Speed)
            case rateChangeCompleted(Float)
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
        case seek
        case rateChange
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
                        .cancel(id: CancelID.seek),
                        .cancel(id: CancelID.rateChange),
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
                    .cancel(id: CancelID.seek),
                    .cancel(id: CancelID.rateChange),
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
                state.currentTime = min(
                    max(time, .zero),
                    state.duration
                )
                return .send(.response(.seekStarted(time)))

            case .skipBackwardTapped:
                let time = max(
                    state.currentTime - state.skipInterval.timeInterval,
                    .zero
                )
                state.currentTime = time
                return .send(.response(.seekStarted(time)))

            case .skipForwardTapped:
                let time = min(
                    state.currentTime + state.skipInterval.timeInterval,
                    state.duration
                )
                state.currentTime = time
                return .send(.response(.seekStarted(time)))

            case .nextPinTapped:
                guard let pin = state.pins.sorted().first(
                    where: { $0 > state.currentTime }
                ) else {
                    return .none
                }
                state.currentTime = pin
                return .send(.response(.seekStarted(pin)))

            case .speedChanged(let speed):
                state.speed = speed
                return .send(.response(.rateChangeStarted(speed)))
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
                state.speed = .init(rawValue: rate) ?? .default
                return .none

            case .audioSessionEvent(.interruptionBegan):
                let notification: Effect<Action> = state.isPlaying
                    ? .send(.delegate(.interrupted))
                    : .none
                state.isPlaying = false
                return .merge(
                    .cancel(id: CancelID.playbackStart),
                    .cancel(id: CancelID.ticker),
                    .run { _ in await playingRecordUsecase.pause() },
                    notification
                )

            case .playbackStarted(.success):
                return .send(.response(.playbackUpdates))

            case .playbackStarted(.failure):
                state.isPlaying = false
                return .send(.delegate(.interrupted))

            case .seekStarted(let time):
                return .run { send in
                    await playingRecordUsecase.seek(time)
                    guard !Task.isCancelled else {
                        return
                    }
                    await send(.response(.seekCompleted(
                        await playingRecordUsecase.currentTime()
                    )))
                }
                .cancellable(
                    id: CancelID.seek,
                    cancelInFlight: true
                )

            case .seekCompleted(let currentTime):
                state.currentTime = currentTime
                return .none

            case .rateChangeStarted(let speed):
                return .run { send in
                    await playingRecordUsecase.changeRate(speed.rawValue)
                    guard !Task.isCancelled else {
                        return
                    }
                    await send(.response(.rateChangeCompleted(
                        await playingRecordUsecase.rate()
                    )))
                }
                .cancellable(
                    id: CancelID.rateChange,
                    cancelInFlight: true
                )

            case .rateChangeCompleted(let rate):
                state.speed = .init(rawValue: rate) ?? .default
                return .none

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
