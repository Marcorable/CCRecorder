
import SwiftUI

import ComposableArchitecture

enum SettingScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            Form {
                GeneralSection(store: store)
                InformationSection(appVersion: store.appVersion)
                TeamSection()
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(
                item: $store.scope(
                    state: \.tutorial,
                    action: \.tutorial
                )
            ) { store in
                OnboardScreen.Root(store: store)
            }
        }
    }

}

#if DEBUG
#Preview {
    NavigationStack {
        SettingScreen.Root(
            store: .init(
                initialState: .init(),
                reducer: { SettingScreen.Root.Feature() }
            )
        )
    }
}
#endif
