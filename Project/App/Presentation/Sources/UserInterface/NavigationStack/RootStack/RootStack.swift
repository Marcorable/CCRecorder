
import SwiftUI

import ComposableArchitecture

struct RootStack: View {
    @State var store: StoreOf<Feature>

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
                switch store.case {
                    case .conversationDetail(let store):
                        ConversationDetailScreen.Root(store: store)

                    case .setting(let store):
                        SettingScreen.Root(store: store)
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
