
import SwiftUI

import ComposableArchitecture

enum RecordScreen {}

extension RecordScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            NavigationView {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        PinGrid(store: store)
                        ConversationInfoBox(
                            store: store.scope(
                                state: \.conversationInfo,
                                action: \.conversationInfo
                            )
                        )
                    }
                    .background(Color(asset: Asset.Surface.Recorder.prominent))
                    .clipShape(.rect(cornerRadius: 25))
                    .padding()
                    RecordingPanel(store: store)
                }
                .padding()
                .background(Color(asset: Asset.Surface.Recorder.muted))
                .navigationTitle("녹음하기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(
                            action: { store.send(.view(.requestCancelButtonTapped)) },
                            label: {
                                Text("취소")
                                    .font(.headline)
                            }
                        )
                    }
                }
            }
            .task {
                await store.send(.view(.task)).finish()
            }
            .onDisappear {
                store.send(.view(.disappeared))
            }
            .alert($store.scope(\.alert, action: \.alert))
        }
    }

}

#if DEBUG
#Preview {
    RecordScreen.Root(
        store: .init(
            initialState: .init(),
            reducer: {
                RecordScreen.Root.Feature.preview
            }
        )
    )
}
#endif
