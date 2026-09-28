import SwiftUI

struct NoteList: View {
    var notes: [Note]
    
    let onDelete: (IndexSet) -> Void
    
    @State private var isPresentedModal: Note?

    var body: some View {
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

#Preview {
    NoteList(
        notes: [.sentenceDummy, .vocabularyDummy],
        onDelete: { _ in }
    )
}
