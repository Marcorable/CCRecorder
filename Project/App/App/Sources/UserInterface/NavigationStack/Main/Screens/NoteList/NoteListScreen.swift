
import SwiftUI
import SwiftData

import Presentation

enum NoteListScreen {

    struct Root: View {
        @Environment(\.modelContext) private var modelContext
        @Query(sort: \Note.createdDate) private var notes: [Note]

        @State private var isPresentedModal: Note?

        var body: some View {
            NoteList(
                notes: sortedNotes,
                onSelect: { isPresentedModal = $0 },
                onDelete: onDelete(at:)
            )
            .navigationTitle("Note")
            .sheet(item: $isPresentedModal) { note in
                PresentationFactory.make(
                    sheet: .noteDetail(
                        .init(
                            id: note.id,
                            createdDate: note.createdDate,
                            original: note.original,
                            translation: note.translation,
                            category: note.category == .vocabulary
                            ? .vocabulary
                            : .sentence
                        )
                    )
                )
            }
        }
    }

}

extension NoteListScreen.Root {

    private var sortedNotes: [Note] { notes.sorted { !($0.isDone && !$1.isDone) } }

    private func onDelete(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(sortedNotes[offset])
        }
    }

}

#Preview {
    NoteListScreen.Root()
}
