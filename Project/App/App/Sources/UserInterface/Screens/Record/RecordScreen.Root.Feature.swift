
import UIKit
import Foundation

import ComposableArchitecture

extension RecordScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.continuousClock) private var clock
        @Dependency(\.date.now) private var now
        @Dependency(\.openURL) private var openURL
        @Dependency(\.recordUsecase) private var recordUsecase
        @Dependency(\.saveConversationUsecase) private var saveConversationUsecase

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
        var isFinished: Bool = false

        var isRecording: Bool { phase == .recording }
        var isAbleToToggleRecording: Bool {
            switch phase {
                case .idle, .recording, .paused:
                    true

                case .preparing, .saving:
                    false
            }
        }
        var isAbleToSave: Bool { currentTime > 0 && phase != .saving }

        enum Phase: Equatable {
            case preparing
            case idle
            case recording
            case paused
            case saving
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case conversationInfo(RecordScreen.ConversationInfoBox.Feature.Action)
        case view(View)
        case response(Response)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case task
            case toggleRecordingButtonTapped
            case addPinButtonTapped
            case removePinButtonTapped(Int)
            case requestCancelButtonTapped
            case requestSaveButtonTapped
            case disappeared
        }

        @CasePathable
        enum Response {
            case prepare(Result<RecordUsecase.State, RecordUsecase.Failure>)
            case recorderUpdated(RecordUsecase.State)
            case save(Result<Void, SaveConversationUsecase.Failure>)
        }

        @CasePathable
        enum Alert {
            case cancelConfirmed
            case saveConfirmed
            case openSettingsTapped
            case closeAfterFailure
        }
    }

    private enum CancelID {
        case prepare
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
                    do {
                        let snapshot = try await recordUsecase.prepare()
                        try Task.checkCancellation()
                        await send(.response(.prepare(.success(snapshot))))
                    } catch is CancellationError {
                        return
                    } catch let failure as RecordUsecase.Failure {
                        await send(.response(.prepare(.failure(failure))))
                    } catch {
                        await send(.response(.prepare(.failure(.prepareFailed))))
                    }
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
                    let snapshot = isRecording
                        ? await recordUsecase.pause()
                        : await recordUsecase.start()
                    await send(.response(.recorderUpdated(snapshot)))
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

            case .disappeared:
                guard !state.isFinished else {
                    return .merge(
                        .cancel(id: CancelID.prepare),
                        .cancel(id: CancelID.ticker)
                    )
                }
                state.isFinished = true
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.ticker),
                    .run { _ in await recordUsecase.cancel() }
                )
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .prepare(.success(let snapshot)):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.currentTime = snapshot.currentTime
                return .none

            case .prepare(.failure(.permissionDenied)):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.alert = .permissionDenied
                return .none

            case .prepare(.failure):
                guard !state.isFinished else {
                    return .none
                }
                state.phase = .idle
                state.alert = .prepareFailed
                return .none

            case .recorderUpdated(let snapshot):
                if snapshot.isRecording {
                    state.phase = .recording
                } else if snapshot.currentTime > 0 {
                    state.phase = .paused
                } else {
                    state.phase = .idle
                }
                state.currentTime = snapshot.currentTime
                guard snapshot.isRecording else {
                    return .cancel(id: CancelID.ticker)
                }
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(100)) {
                        await send(.response(.recorderUpdated(await recordUsecase.state())))
                    }
                }
                .cancellable(
                    id: CancelID.ticker,
                    cancelInFlight: true
                )

            case .save(.success):
                state.isFinished = true
                return .none

            case .save(.failure):
                state.phase = .idle
                state.alert = .saveFailed
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Alert
    ) -> Effect<Action> {
        switch action {
            case .cancelConfirmed:
                state.isFinished = true
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.ticker),
                    .run { _ in await recordUsecase.cancel() }
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
                            let fileURL = try await recordUsecase.finish()
                            try await saveConversationUsecase.execute(
                                .init(
                                    fileURL: fileURL,
                                    createdDate: createdDate,
                                    title: savingTitle,
                                    topic: topic,
                                    parties: parties,
                                    pins: pins
                                )
                            )
                            await send(.response(.save(.success(()))))
                        } catch {
                            await send(.response(.save(.failure(.saveFailed))))
                        }
                    }
                )

            case .openSettingsTapped:
                state.isFinished = true
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.ticker),
                    .run { _ in
                        guard let url = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        await openURL(url)
                    },
                    .run { _ in await recordUsecase.cancel() }
                )

            case .closeAfterFailure:
                state.isFinished = true
                return .merge(
                    .cancel(id: CancelID.prepare),
                    .cancel(id: CancelID.ticker),
                    .run { _ in await recordUsecase.cancel() }
                )
        }
    }

}
