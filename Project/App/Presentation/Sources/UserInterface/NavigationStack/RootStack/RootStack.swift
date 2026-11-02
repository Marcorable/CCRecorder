
import SwiftUI

import ComposableArchitecture

struct RootStack: View {
    @Bindable var store: StoreOf<Feature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                \.path,
                action: \.path
            ),
            root: {
                MainScreen.Root(
                    store: store.scope(
                        state: \.main,
                        action: \.main
                    )
                )
            },
            destination: { store in
                switch store.state {
                    case .conversationDetail:
                        if let store = store.scope(
                            state: \.conversationDetail,
                            action: \.conversationDetail
                        ) {
                            ConversationDetailScreen.Root(store: store)
                        }

                    case .setting:
                        if let store = store.scope(
                            state: \.setting,
                            action: \.setting
                        ) {
                            SettingScreen.Root(store: store)
                        }
                }
            }
        )
    }
}

#if DEBUG
#Preview {
    RootStack(
        store: .init(
            initialState: .init(),
            reducer: {
                RootStack.Feature.preview
            }
        )
    )
}
#endif
