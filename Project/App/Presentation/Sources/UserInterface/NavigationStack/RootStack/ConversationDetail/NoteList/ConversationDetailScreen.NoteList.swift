
import SwiftUI

import Domain

extension ConversationDetailScreen {

    struct NoteList: View {
        let notes: [Note]
        let select: (Note.ID) -> Void
        let delete: (IndexSet) -> Void

        var body: some View {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Notes from your conversations will appear here.")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            Row(note: note)
                                .onTapGesture {
                                    select(note.id)
                                }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

}
