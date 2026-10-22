
import SwiftUI
import SwiftData

extension NoteListScreen {

    struct Context: View {
        @Environment(\.modelContext) private var modelContext
        @Query(sort: \Note.createdDate) private var notes: [Note]

        var body: some View {
            NoteList(
                notes: sortedNotes,
                onDelete: onDelete(at:)
            )
            .navigationTitle("Note")
        }
    }

}

extension NoteListScreen.Context {

    private var sortedNotes: [Note] { notes.sorted { !($0.isDone && !$1.isDone) } }

    private func onDelete(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(sortedNotes[offset])
        }
    }

}

#Preview {
    NoteListScreen.Context()
}
