
import SwiftUI

import ComposableArchitecture

extension MainScreen {

    struct ConversationList: View {
        let store: StoreOf<Feature>

        var body: some View {
            Group {
                if let rows = store.rows {
                    if rows.isEmpty {
                        ContentUnavailableView(
                            "No Conversations",
                            systemImage: "waveform",
                            description: Text("Record a conversation to see it here.")
                        )
                    } else {
                        List {
                            ForEach(rows) { row in
                                Row(viewModel: row)
                                    .onTapGesture {
                                        store.send(.view(.conversationTapped(row.id)))
                                    }
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { store.send(.view(.deleteRequested($0))) }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Conversation")
            .task {
                await store.send(.view(.task)).finish()
            }
        }
    }

}

#Preview {
    NavigationStack {
        MainScreen.ConversationList(
            store: .init(
                initialState: .init(),
                reducer: { MainScreen.ConversationList.Feature() },
                withDependencies: {
                    $0.managingConversationUsecase.conversations = {
                        .success([
                            .init(
                                createdDate: .init(),
                                pins: [],
                                title: "Daily Conversation",
                                topic: "Weekend plans",
                                parties: [
                                    .init(name: "Marco"),
                                    .init(name: "Coda"),
                                ]
                            ),
                        ])
                    }
                }
            )
        )
    }
}
