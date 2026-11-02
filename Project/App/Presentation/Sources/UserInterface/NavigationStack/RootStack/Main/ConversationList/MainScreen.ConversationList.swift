
import SwiftUI

import ComposableArchitecture

extension MainScreen {

    struct ConversationList: View {
        let store: StoreOf<Feature>

        var body: some View {
            Group {
                if store.isLoading, store.conversations == nil {
                    ProgressView()
                } else if let rows = store.rows, !rows.isEmpty {
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
                } else {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "waveform",
                        description: Text("Record a conversation to see it here.")
                    )
                }
            }
            .navigationTitle("Conversation")
            .task {
                await store.send(.view(.task)).finish()
            }
        }
    }

}
