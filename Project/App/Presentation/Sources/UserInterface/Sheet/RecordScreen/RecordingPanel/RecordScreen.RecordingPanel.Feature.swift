
import Foundation

import Domain
import ComposableArchitecture

extension RecordScreen.RecordingPanel {

    @Reducer
    struct Feature {
        @Dependency(\.continuousClock) private var clock
        @Dependency(\.audioSession) private var audioSession
        @Dependency(\.recordingUsecase) private var recordingUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .parent(let action):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .view(let action):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .response(let action):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .delegate:
                        return .none
                }
            }
        }
    }

}

extension RecordScreen.RecordingPanel.Feature {

    @ObservableState
    struct State: Equatable {
        var phase: Phase = .preparing
        var currentTime: TimeInterval = .zero
        var pins: [TimeInterval] = []

        var isRecording: Bool {
            phase == .recording
        }

        var isFinished: Bool {
            phase == .finished
        }

        var isLoading: Bool {
            switch phase {
                case .preparing, .saving:                       true
                case .idle, .recording, .paused, .finished:     false
            }
        }

        var isAbleToToggleRecording: Bool {
            switch phase {
                case .idle, .recording, .paused:       true
                case .preparing, .saving, .finished:   false
            }
        }

        var isAbleToSave: Bool {
            switch phase {
                case .idle, .recording, .paused:       currentTime > .zero
                case .preparing, .saving, .finished:   false
            }
        }

        var isRecordingIndicatorVisible: Bool {
            !isRecording || Int(currentTime).isMultiple(of: 2)
        }

        enum Phase: Equatable {
            case preparing
            case idle
            case recording
            case paused
            case saving
            case finished
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case parent(Parent)
        case view(View)
        case response(Response)
        case delegate(Delegate)

        @CasePathable
        enum Parent {
            case screenAppeared
            case discardConfirmed
            case saveConfirmed(Conversation)
        }

        @CasePathable
        enum View {
            case toggleRecordingButtonTapped
            case addPinButtonTapped
            case removePinButtonTapped(Int)
            case requestSaveButtonTapped
        }

        @CasePathable
        enum Response {
            case recordingPreparing
            case recordingPrepared(TimeInterval)
            case recorderUpdated(isRecording: Bool, currentTime: TimeInterval)
            case recordingDiscarding
            case recordingSaving(Conversation)
            case recordingSaved
            case recordingFailed(DomainError.RecordingUsecaseFailure)
        }

        @CasePathable
        enum Delegate {
            case authorizationUnavailable
            case saveRequested
            case recordingDiscarded
            case recordingSaved
            case recordingFailed(DomainError.RecordingUsecaseFailure)
        }
    }

    private enum CancelID {
        case prepare
        case save
        case ticker
    }

}

extension RecordScreen.RecordingPanel.Feature {

    private func reduce(
        into state: inout State,
        action: Action.Parent
    ) -> Effect<Action> {
        switch action {
            case .screenAppeared:
                state.phase = .preparing
                return .send(.response(.recordingPreparing))

            case .discardConfirmed:
                state.phase = .finished
                return .send(.response(.recordingDiscarding))

            case .saveConfirmed(let conversation):
                state.phase = .saving
                return .send(.response(.recordingSaving(conversation)))
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .toggleRecordingButtonTapped:
                guard state.isAbleToToggleRecording else {
                    return .none
                }
                let isRecording = state.isRecording
                return .run { send in
                    if isRecording {
                        await recordingUsecase.pause()
                    } else {
                        await recordingUsecase.start()
                    }
                    await send(
                        .response(
                            .recorderUpdated(
                                isRecording: await recordingUsecase.isRecording(),
                                currentTime: await recordingUsecase.currentTime()
                            )
                        )
                    )
                }

            case .addPinButtonTapped:
                guard state.isRecording else {
                    return .none
                }
                state.pins.append(state.currentTime)
                return .none

            case .removePinButtonTapped(let index):
                guard state.pins.indices.contains(index) else {
                    return .none
                }
                state.pins.remove(at: index)
                return .none

            case .requestSaveButtonTapped:
                guard state.isAbleToSave else {
                    return .none
                }
                return .send(.delegate(.saveRequested))
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .recordingPreparing:
                switch audioSession.authorizationStatus() {
                    case .authorized:
                        return .run { send in
                            do {
                                try audioSession.activate()
                                try await recordingUsecase.prepare()
                                try Task.checkCancellation()
                                await send(.response(.recordingPrepared(
                                    await recordingUsecase.currentTime()
                                )))
                            } catch is CancellationError {
                                return
                            } catch let DomainError.recordingUsecase(error) {
                                await send(.response(.recordingFailed(error)))
                            } catch {
                                await send(.response(.recordingFailed(.prepareFailed)))
                            }
                        }
                        .cancellable(
                            id: CancelID.prepare,
                            cancelInFlight: true
                        )

                    case .notDetermined, .denied:
                        guard !state.isFinished else {
                            return .none
                        }
                        state.phase = .finished
                        return .send(.delegate(.authorizationUnavailable))
                }

            case .recordingPrepared(let currentTime):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.currentTime = currentTime
                return .none

            case .recorderUpdated(let isRecording, let currentTime):
                guard !state.isFinished else {
                    return .none
                }
                if isRecording {
                    state.phase = .recording
                } else if currentTime > 0 {
                    state.phase = .paused
                } else {
                    state.phase = .idle
                }
                state.currentTime = currentTime
                guard isRecording else {
                    return .cancel(id: CancelID.ticker)
                }
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(100)) {
                        await send(
                            .response(
                                .recorderUpdated(
                                    isRecording: await recordingUsecase.isRecording(),
                                    currentTime: await recordingUsecase.currentTime()
                                )
                            )
                        )
                    }
                }
                .cancellable(
                    id: CancelID.ticker,
                    cancelInFlight: true
                )

            case .recordingDiscarding:
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.save),
                    .cancel(id: CancelID.ticker),
                    .run { send in
                        await recordingUsecase.cancel()
                        await send(.delegate(.recordingDiscarded))
                    }
                )

            case .recordingSaving(let conversation):
                return .merge(
                    .cancel(id: CancelID.ticker),
                    .run { send in
                        do {
                            try await recordingUsecase.finish(conversation)
                            await send(.response(.recordingSaved))
                        } catch is CancellationError {
                            return
                        } catch let DomainError.recordingUsecase(error) {
                            await send(.response(.recordingFailed(error)))
                        } catch {
                            await send(.response(.recordingFailed(.saveFailed)))
                        }
                    }
                    .cancellable(
                        id: CancelID.save,
                        cancelInFlight: true
                    )
                )

            case .recordingSaved:
                state.phase = .finished
                return .send(.delegate(.recordingSaved))

            case .recordingFailed(let error):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                return .send(.delegate(.recordingFailed(error)))
        }
    }

}
