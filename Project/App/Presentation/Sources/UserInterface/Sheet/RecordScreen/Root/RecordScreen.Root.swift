
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
                        PinGrid(
                            store: store.scope(
                                state: \.recordingPanel,
                                action: \.recordingPanel
                            )
                        )
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
                    RecordingPanel(
                        store: store.scope(
                            state: \.recordingPanel,
                            action: \.recordingPanel
                        )
                    )
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
            .disabled(store.isLoading)
            .overlay {
                if store.isLoading {
                    LoadingProgress()
                }
            }
            .task {
                await store.send(.view(.task)).finish()
            }
            .alert($store.scope(\.alert, action: \.alert))
        }
    }

}

#Preview {
    RecordScreen.Root(
        store: .init(
            initialState: .init(),
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .authorized }
                $0.audioSession.activate = {}
                $0.recordingUsecase = .preview
            }
        )
    )
}
