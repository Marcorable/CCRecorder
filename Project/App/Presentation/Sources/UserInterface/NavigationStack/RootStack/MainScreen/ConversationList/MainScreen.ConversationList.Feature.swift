
import Foundation

import Domain
import ComposableArchitecture

extension MainScreen.ConversationList {

    @Reducer
    struct Feature {
        @Dependency(\.managingConversationUsecase) private var managingConversationUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
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

extension MainScreen.ConversationList.Feature {

    typealias Row = MainScreen.ConversationList.Row.ViewModel

    @ObservableState
    struct State: Equatable {
        var isLoading = false

        fileprivate var conversations: [Conversation]?

        var rows: [Row]? {
            conversations?.map({
                .init(
                    id: $0.id,
                    title: $0.title,
                    topic: $0.topic,
                    attendeeCount: $0.parties.count,
                    createdDate: $0.createdDate,
                    isChecked: !$0.title.isEmpty && !$0.topic.isEmpty && !$0.parties.isEmpty
                )
            })
        }
    }

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case response(Response)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case task
            case reload
            case conversationTapped(Conversation.ID)
            case deleteRequested(IndexSet)
        }

        @CasePathable
        enum Response {
            case conversationsLoading
            case conversationsLoaded(Result<[Conversation], DomainError>)
            case conversationsDeleted(
                ids: [Conversation.ID],
                result: Result<Void, DomainError>
            )
        }

        @CasePathable
        enum Delegate {
            case conversationSelected(Conversation.ID)
            case loadFailed
            case deleteFailed
        }
    }

    private enum CancelID {
        case loadConversations
    }

}

extension MainScreen.ConversationList.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .task:
                guard state.conversations == nil, !state.isLoading else {
                    return .none
                }
                state.isLoading = true
                return .send(.response(.conversationsLoading))

            case .reload:
                state.isLoading = true
                return .send(.response(.conversationsLoading))

            case .conversationTapped(let id):
                guard state.conversations?.contains(where: { $0.id == id }) == true else {
                    return .none
                }
                return .send(.delegate(.conversationSelected(id)))

            case .deleteRequested(let offsets):
                guard let conversations = state.conversations else {
                    return .none
                }
                let targets = offsets.compactMap({ index in
                    conversations.indices.contains(index) ? conversations[index] : nil
                })
                guard !targets.isEmpty else {
                    return .none
                }
                return .run { send in
                    await send(
                        .response(
                            .conversationsDeleted(
                                ids: targets.map(\.id),
                                result: await managingConversationUsecase.deleteConversations(targets)
                            )
                        )
                    )
                }
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .conversationsLoading:
                return .run { send in
                    await send(.response(.conversationsLoaded(
                        await managingConversationUsecase.conversations()
                    )))
                }
                .cancellable(
                    id: CancelID.loadConversations,
                    cancelInFlight: true
                )

            case .conversationsLoaded(.success(let conversations)):
                state.isLoading = false
                state.conversations = conversations.sorted(by: { $0.createdDate < $1.createdDate })
                return .none

            case .conversationsLoaded(.failure):
                state.isLoading = false
                return .send(.delegate(.loadFailed))

            case .conversationsDeleted(let ids, .success):
                state.conversations?.removeAll(where: { ids.contains($0.id) })
                return .none

            case .conversationsDeleted(_, .failure):
                return .send(.delegate(.deleteFailed))
        }
    }

}
