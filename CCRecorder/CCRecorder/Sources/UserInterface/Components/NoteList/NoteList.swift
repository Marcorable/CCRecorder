
import SwiftUI

struct NoteList: View {
    let notes: [Note]
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
                        Row(note: note)
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
                .presentationDetents(note.category.noteDetailPresentationDetents)
        }
    }
}

private extension Note.Category {

    var noteDetailPresentationDetents: Set<PresentationDetent> {
        switch self {
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
