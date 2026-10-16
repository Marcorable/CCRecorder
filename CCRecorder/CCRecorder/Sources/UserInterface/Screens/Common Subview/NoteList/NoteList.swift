import SwiftUI

struct NoteList: View {
    var notes: [Note]
    
    let onDelete: (IndexSet) -> Void
    
    @State private var isPresentedModal: Note?

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
                    ForEach(notes, id: \.id) { note in
                        NoteListRow(note: note)
                            .onTapGesture {
                                isPresentedModal = note
                            }
                    }
                    .onDelete(perform: onDelete)
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $isPresentedModal) { note in
            NoteDetail(note: note)
                .presentationDetents(detents(of: note.category))
        }
    }
    
}

private extension NoteList {
    
    func detents(of category: Note.Category) -> Set<PresentationDetent> {
        switch category {
            case .vocabulary:   [.medium]
            case .sentence:     [.medium, .large]
        }
    }
    
}

#if DEBUG
#Preview {
    NoteList(
        notes: [.sentenceDummy, .vocabularyDummy],
        onDelete: { _ in }
    )
}
#endif
