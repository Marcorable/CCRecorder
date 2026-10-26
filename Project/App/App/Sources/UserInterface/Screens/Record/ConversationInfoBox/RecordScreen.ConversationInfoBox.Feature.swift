
import Foundation

import ComposableArchitecture

extension RecordScreen.ConversationInfoBox {

    @Reducer
    struct Feature {
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

            enum View {
                case clearTitleButtonTapped
                case clearTopicButtonTapped
                case clearPartyNameButtonTapped
                case editingButtonTapped
                case addParty
                case removePartyButtonTapped(Int)
            }
        }

        var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    case .binding:
                        return .none

                    case .view(.clearTitleButtonTapped):
                        state.title = ""
                        return .none

                    case .view(.clearTopicButtonTapped):
                        state.topic = ""
                        return .none

                    case .view(.clearPartyNameButtonTapped):
                        state.partyName = ""
                        return .none

                    case .view(.editingButtonTapped):
                        state.isEditing.toggle()
                        return .none

                    case .view(.addParty):
                        guard !state.partyName.isEmpty else {
                            return .none
                        }
                        state.parties.insert(state.partyName, at: 0)
                        state.partyName = ""
                        return .none

                    case .view(.removePartyButtonTapped(let index)):
                        guard state.parties.indices.contains(index) else {
                            return .none
                        }
                        state.parties.remove(at: index)
                        return .none
                }
            }
        }
    }

}
