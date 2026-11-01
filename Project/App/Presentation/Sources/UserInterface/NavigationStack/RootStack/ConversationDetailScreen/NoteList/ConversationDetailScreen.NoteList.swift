
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen {

    struct NoteList: View {
        let store: StoreOf<Notes.Feature>

        var body: some View {
            Group {
                if store.notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Notes from your conversations will appear here.")
                    )
                } else {
                    List {
                        ForEach(store.notes) { note in
                            Row(note: note)
                                .onTapGesture {
                                    store.send(.view(.noteSelected(note.id)))
                                }
                        }
                        .onDelete { store.send(.view(.notesDeleted($0))) }
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

}
