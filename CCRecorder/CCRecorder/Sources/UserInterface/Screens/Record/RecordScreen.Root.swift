
import SwiftUI

import ComposableArchitecture

enum RecordScreen {}

extension RecordScreen {

    struct Root: View {
        @Environment(\.dismiss) private var dismiss

        @Bindable var store: StoreOf<Feature>

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
                    .background(Color.Surface.Recorder.prominent)
                    .clipShape(.rect(cornerRadius: 25))
                    .padding()
                    RecordingPanel(store: store)
                }
                .padding()
                .background(Color.Surface.Recorder.muted)
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
            .onChange(of: store.isFinished) {
                if store.isFinished {
                    dismiss()
                }
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
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.recordUsecase = .live(
                    service: MockRecorderService()
                )
                $0.saveConversationUsecase = .live(
                    repository: ConversationRepositoryConcrete(
                        modelContext: .mock
                    ),
                    fileStore: RecordFileStore()
                )
            }
        )
    )
}
#endif
