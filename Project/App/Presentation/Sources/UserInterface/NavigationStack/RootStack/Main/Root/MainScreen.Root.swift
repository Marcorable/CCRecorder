
import SwiftUI

import ComposableArchitecture

enum MainScreen {

    enum Tab: Equatable {
        case conversationList
        case noteList
    }

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            VStack {
                switch store.selectedTab {
                    case .conversationList:
                        MainScreen.ConversationList(
                            store: store.scope(
                                state: \.conversationList,
                                action: \.conversationList
                            )
                        )

                    case .noteList:
                        MainScreen.NoteList(
                            store: store.scope(
                                state: \.noteList,
                                action: \.noteList
                            )
                        )
                }
                MainScreen.TabBar(
                    selectedTab: store.selectedTab,
                    select: { store.send(.view(.tabSelected($0))) },
                    record: { store.send(.view(.recordButtonTapped)) }
                )
            }
            .background(Color.Surface.Background.primary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: { store.send(.view(.settingButtonTapped)) },
                        label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.accent)
                        }
                    )
                }
            }
            .fullScreenCover(
                item: $store.scope(
                    state: \.onboard,
                    action: \.onboard
                )
            ) { store in
                OnboardScreen.Root(store: store)
            }
            .fullScreenCover(
                item: $store.scope(
                    state: \.record,
                    action: \.record
                )
            ) { store in
                RecordScreen.Root(store: store)
            }
            .sheet(
                item: $store.scope(
                    state: \.noteDetail,
                    action: \.noteDetail
                )
            ) { store in
                NoteDetailScreen.Root(store: store)
                    .presentationDetents(store.note.category.presentationDetents)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }

}

#if DEBUG
#Preview {
    MainScreen.Root(
        store: .init(
            initialState: .init(),
            reducer: {
                MainScreen.Root.Feature.preview
            }
        )
    )
}
#endif
