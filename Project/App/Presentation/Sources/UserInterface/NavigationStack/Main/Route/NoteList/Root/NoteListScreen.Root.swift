
import SwiftUI

import ComposableArchitecture

enum NoteListScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            Group {
                if store.isLoading, store.notes == nil {
                    ProgressView()
                } else if let rows = store.rows {
                    NoteList(
                        rows: rows,
                        onSelect: { store.send(.view(.noteTapped($0))) },
                        onDelete: { store.send(.view(.deleteRequested($0))) }
                    )
                } else {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Notes from your conversations will appear here.")
                    )
                }
            }
            .navigationTitle("Note")
            .task {
                await store.send(.view(.task)).finish()
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
    NavigationStack {
        NoteListScreen.Root(
            store: .init(
                initialState: .init(),
                reducer: {
                    NoteListScreen.Root.Feature.preview
                }
            )
        )
    }
}
#endif
