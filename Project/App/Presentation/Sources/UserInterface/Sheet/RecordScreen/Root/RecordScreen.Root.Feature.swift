
import Foundation

import Domain
import ComposableArchitecture

extension RecordScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.date.now) private var now
        @Dependency(\.dismiss) private var dismiss

        var body: some ReducerOf<Self> {
            Scope(
                state: \.conversationInfo,
                action: \.conversationInfo
            ) {
                RecordScreen.ConversationInfoBox.Feature()
            }
            Scope(
                state: \.recordingPanel,
                action: \.recordingPanel
            ) {
                RecordScreen.RecordingPanel.Feature()
            }
            Reduce { state, action in
                switch action {
                    case .view(let action):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .recordingPanel(.delegate(let action)):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .alert(.presented(let action)):
                        return reduce(
                            into: &state,
                            action: action
                        )

                    case .conversationInfo, .recordingPanel, .delegate, .alert:
                        return .none
                }
            }
            .ifLet(\.$alert, action: \.alert)
        }
    }

}

extension RecordScreen.Root.Feature {

    typealias RecordingPanelDelegate = RecordScreen.RecordingPanel.Feature.Action.Delegate

    @ObservableState
    struct State: Equatable {
        var conversationInfo: RecordScreen.ConversationInfoBox.Feature.State = .init()
        var recordingPanel: RecordScreen.RecordingPanel.Feature.State = .init()

        @Presents var alert: AlertState<Action.Alert>?

        var isLoading: Bool {
            recordingPanel.isLoading
        }

        var isFinished: Bool {
            recordingPanel.isFinished
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case conversationInfo(RecordScreen.ConversationInfoBox.Feature.Action)
        case recordingPanel(RecordScreen.RecordingPanel.Feature.Action)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {
            case task
            case requestCancelButtonTapped
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

}

extension RecordScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .task:
                return .send(.recordingPanel(.parent(.screenAppeared)))

            case .requestCancelButtonTapped:
                state.alert = .confirmCancel
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: RecordingPanelDelegate
    ) -> Effect<Action> {
        switch action {
            case .authorizationUnavailable:
                return .send(.delegate(.authorizationUnavailable))

            case .saveRequested:
                state.alert = .confirmSave
                return .none

            case .recordingDiscarded, .recordingSaved:
                return .run { _ in
                    await dismiss()
                }

            case .recordingFailed(.prepareFailed):
                state.alert = .prepareFailed
                return .none

            case .recordingFailed(.finishFailed),
                    .recordingFailed(.saveFailed):
                state.alert = .saveFailed
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Alert
    ) -> Effect<Action> {
        switch action {
            case .cancelConfirmed, .closeAfterFailure:
                return .send(.recordingPanel(.parent(.discardConfirmed)))

            case .saveConfirmed:
                let createdDate = now
                let title = state.conversationInfo.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let savingTitle = !title.isEmpty
                    ? title
                    : createdDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                let conversation: Conversation = .init(
                    createdDate: createdDate,
                    pins: state.recordingPanel.pins,
                    title: savingTitle,
                    topic: state.conversationInfo.topic,
                    parties: state.conversationInfo.parties.map({ .init(name: $0) })
                )
                return .send(.recordingPanel(.parent(.saveConfirmed(conversation))))
        }
    }

}
