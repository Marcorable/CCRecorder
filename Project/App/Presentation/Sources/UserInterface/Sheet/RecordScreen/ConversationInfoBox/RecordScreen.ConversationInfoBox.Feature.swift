
import Foundation

import ComposableArchitecture

extension RecordScreen.ConversationInfoBox {

    @Reducer
    struct Feature {
        var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    case .binding:
                        return .none

                    case .view(let action):
                        return reduce(
                            into: &state,
                            action: action
                        )
                }
            }
        }
    }

}

extension RecordScreen.ConversationInfoBox.Feature {

    @ObservableState
    struct State: Equatable {
        var title = Date.now.formatted(
            date: .abbreviated,
            time: .omitted
        )
        var topic = ""
        var partyName = ""
        var parties: [String] = []
        var isEditing = false
    }

    @CasePathable
    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case view(View)

        @CasePathable
        enum View {
            case clearTitleButtonTapped
            case clearTopicButtonTapped
            case clearPartyNameButtonTapped
            case editingButtonTapped
            case addParty
            case removePartyButtonTapped(Int)
        }
    }

}

extension RecordScreen.ConversationInfoBox.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .clearTitleButtonTapped:
                state.title = ""
                return .none

            case .clearTopicButtonTapped:
                state.topic = ""
                return .none

            case .clearPartyNameButtonTapped:
                state.partyName = ""
                return .none

            case .editingButtonTapped:
                state.isEditing.toggle()
                return .none

            case .addParty:
                guard !state.partyName.isEmpty else {
                    return .none
                }
                state.parties.insert(state.partyName, at: 0)
                state.partyName = ""
                return .none

            case .removePartyButtonTapped(let index):
                guard state.parties.indices.contains(index) else {
                    return .none
                }
                state.parties.remove(at: index)
                return .none
        }
    }

}
