
import Foundation

import Domain
import ComposableArchitecture

extension RecordScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.continuousClock) private var clock
        @Dependency(\.date.now) private var now
        @Dependency(\.dismiss) private var dismiss
        @Dependency(\.audioSession) private var audioSession
        @Dependency(\.recordingUsecase) private var recordingUsecase

        var body: some ReducerOf<Self> {
            Scope(
                state: \.conversationInfo,
                action: \.conversationInfo
            ) {
                RecordScreen.ConversationInfoBox.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .conversationInfo:
                        return .none

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

                    case .alert(.presented(let action)):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .alert:
                        return .none
                }
            }
            .ifLet(\.$alert, action: \.alert)
        }
    }

}

extension RecordScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?

        var conversationInfo: RecordScreen.ConversationInfoBox.Feature.State = .init()
        var phase: Phase = .preparing
        var currentTime: TimeInterval = .zero
        var pins: [TimeInterval] = []

        var isRecording: Bool { phase == .recording }
        var isFinished: Bool { phase == .finished }
        var isAbleToToggleRecording: Bool {
            switch phase {
                case .idle, .recording, .paused:
                    true

                case .preparing, .saving, .finished:
                    false
            }
        }
        var isAbleToSave: Bool {
            currentTime > 0 && phase != .saving && phase != .finished
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
        case conversationInfo(RecordScreen.ConversationInfoBox.Feature.Action)
        case view(View)
        case response(Response)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case task
            case toggleRecordingButtonTapped
            case addPinButtonTapped
            case removePinButtonTapped(Int)
            case requestCancelButtonTapped
            case requestSaveButtonTapped
        }

        @CasePathable
        enum Response {
            case audioSessionAuthorization(AudioSessionClient.Status)
            case prepared(TimeInterval)
            case recorderUpdated(isRecording: Bool, currentTime: TimeInterval)
            case saved
            case recordingFailed(DomainError.RecordingUsecaseFailure)
        }

        @CasePathable
        enum Delegate {
            case authorizationUnavailable
        }

        @CasePathable
        enum Alert {
            case cancelConfirmed
            case saveConfirmed
            case closeAfterFailure
        }
    }

    private enum CancelID {
        case prepare
        case save
        case ticker
    }

}

extension RecordScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .task:
                state.phase = .preparing
                return .run { send in
                    let status = audioSession.authorizationStatus()
                    try Task.checkCancellation()
                    await send(.response(.audioSessionAuthorization(status)))
                }
                .cancellable(
                    id: CancelID.prepare,
                    cancelInFlight: true
                )

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

            case .requestCancelButtonTapped:
                state.alert = .confirmCancel
                return .none

            case .requestSaveButtonTapped:
                guard state.isAbleToSave else {
                    return .none
                }
                state.alert = .confirmSave
                return .none

        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .audioSessionAuthorization(.authorized):
                return .run { send in
                    do {
                        try audioSession.activate()
                        try await recordingUsecase.prepare()
                        try Task.checkCancellation()
                        await send(.response(.prepared(await recordingUsecase.currentTime())))
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

            case .audioSessionAuthorization(.notDetermined),
                    .audioSessionAuthorization(.denied):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .finished
                return .send(.delegate(.authorizationUnavailable))

            case .prepared(let currentTime):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.currentTime = currentTime
                return .none

            case .recordingFailed(.prepareFailed):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.alert = .prepareFailed
                return .none

            case .recordingFailed(.finishFailed),
                    .recordingFailed(.saveFailed):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.alert = .saveFailed
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

            case .saved:
                state.phase = .finished
                return .run { _ in
                    await dismiss()
                }

        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Alert
    ) -> Effect<Action> {
        switch action {
            case .cancelConfirmed:
                state.phase = .finished
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.save),
                    .cancel(id: CancelID.ticker),
                    .run { _ in
                        await recordingUsecase.cancel()
                        await dismiss()
                    }
                )

            case .saveConfirmed:
                state.phase = .saving
                let createdDate = now
                let title = state.conversationInfo.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let savingTitle = !title.isEmpty
                    ? title
                    : createdDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                let topic = state.conversationInfo.topic
                let parties = state.conversationInfo.parties
                let pins = state.pins
                return .merge(
                    .cancel(id: CancelID.ticker),
                    .run { send in
                        do {
                            try await recordingUsecase.finish(
                                .init(
                                    createdDate: createdDate,
                                    pins: pins,
                                    title: savingTitle,
                                    topic: topic,
                                    parties: parties.map({ .init(name: $0) })
                                )
                            )
                            await send(.response(.saved))
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

            case .closeAfterFailure:
                state.phase = .finished
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.save),
                    .cancel(id: CancelID.ticker),
                    .run { _ in
                        await recordingUsecase.cancel()
                        await dismiss()
                    }
                )
        }
    }

}
