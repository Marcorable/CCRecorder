import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdDate) private var notes: [Note]
    
    private var sortedNotes: [Note] { notes.sorted { !($0.isDone && !$1.isDone) } }
    
    var body: some View {
        NoteList(
            notes: sortedNotes,
            onDelete: onDelete(at:)
        )
        .navigationTitle("Note")
    }
    
}

private extension NoteListView {
    
    func onDelete(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(sortedNotes[offset])
        }
    }
    
}

#Preview {
    NoteListView()
}
