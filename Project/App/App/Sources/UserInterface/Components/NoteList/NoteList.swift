
import SwiftUI

struct NoteList: View {
    let notes: [Note]
    let onSelect: (Note) -> Void
    let onDelete: (IndexSet) -> Void

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
                                onSelect(note)
                            }
                    }
                    .onDelete(perform: onDelete)
                }
                .listStyle(.plain)
            }
        }
    }
}

#if DEBUG
#Preview {
    NoteList(
        notes: [
            .init(
                original: "",
                translation: "테스트 용 문장을 이렇게 작성함",
                category: .sentence
            ),
            .init(
                original: "Test",
                translation: "",
                category: .vocabulary
            )
        ],
        onSelect: { _ in },
        onDelete: { _ in }
    )
}
#endif
