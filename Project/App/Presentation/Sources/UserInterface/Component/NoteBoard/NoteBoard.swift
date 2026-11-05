
import SwiftUI

struct NoteBoard: View {
    let rows: [Row.ViewModel]?
    let onTap: (Row.ViewModel.ID) -> Void
    let onDelete: ([Row.ViewModel.ID]) -> Void

    var body: some View {
        Group {
            if let rows {
                if rows.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Notes from your conversations will appear here.")
                    )
                } else {
                    List {
                        ForEach(rows) { row in
                            Row(viewModel: row)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(
                                    .init(
                                        top: 12,
                                        leading: 12,
                                        bottom: .zero,
                                        trailing: 12
                                    )
                                )
                                .onTapGesture {
                                    onTap(row.id)
                                }
                        }
                        .onDelete { offsets in
                            onDelete(
                                offsets.compactMap({ index in
                                    rows.indices.contains(index)
                                    ? rows[index].id
                                    : nil
                                })
                            )
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, .zero)
                }
            } else {
                ProgressView()
            }
        }
    }
}

#Preview("Loading") {
    NoteBoard(
        rows: nil,
        onTap: { _ in },
        onDelete: { _ in }
    )
}

#Preview("Empty") {
    NoteBoard(
        rows: [],
        onTap: { _ in },
        onDelete: { _ in }
    )
}

#Preview("Rows") {
    NoteBoard(
        rows: [
            .init(
                id: .init(),
                original: "How have you been?",
                translation: "어떻게 지냈어요?",
                isVocabulary: false
            ),
            .init(
                id: .init(),
                original: "Apple",
                translation: "",
                isVocabulary: true
            ),
            .init(
                id: .init(),
                original: "",
                translation: "무슨 말을 해야할지 모르겠어",
                isVocabulary: true
            )
        ],
        onTap: { _ in },
        onDelete: { _ in }
    )
}
