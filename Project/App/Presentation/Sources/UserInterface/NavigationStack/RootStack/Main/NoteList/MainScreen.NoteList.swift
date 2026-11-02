
import SwiftUI

import ComposableArchitecture

extension MainScreen {

    struct NoteList: View {
        let store: StoreOf<Feature>

        var body: some View {
            Group {
                if store.isLoading, store.notes == nil {
                    ProgressView()
                } else if let rows = store.rows, !rows.isEmpty {
                    List {
                        ForEach(rows) { row in
                            Row(viewModel: row)
                                .onTapGesture {
                                    store.send(.view(.noteTapped(row.id)))
                                }
                        }
                        .onDelete { store.send(.view(.deleteRequested($0))) }
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Notes from your conversations will appear here.")
                    )
                }
            }
            .accessibilityIdentifier("main.noteList")
            .navigationTitle("Note")
            .task {
                await store.send(.view(.task)).finish()
            }
        }
    }

}
