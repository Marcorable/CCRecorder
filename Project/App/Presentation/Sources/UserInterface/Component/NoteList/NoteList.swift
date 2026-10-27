
import SwiftUI
import Foundation

// 임시
struct NoteList: View {
    let rows: [Row.ViewModel]
    let onSelect: (Row.ViewModel.ID) -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        Group {
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
                            .onTapGesture {
                                onSelect(row.id)
                            }
                    }
                    .onDelete(perform: onDelete)
                }
                .listStyle(.plain)
            }
        }
    }
}

extension NoteList {

    struct Row: View {
        let viewModel: ViewModel

        var body: some View {
            HStack {
                Image(systemName: viewModel.categoryImageName)
                    .foregroundStyle(Color(asset: Asset.Logo.Prominent.red))
                    .frame(
                        width: 36,
                        alignment: .center
                    )

                VStack(alignment: .leading) {
                    if viewModel.isDone {
                        Text(viewModel.original)
                        Text(viewModel.translation)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        Text(viewModel.noteContentLabel)
                        Text(viewModel.suggestLabel)
                            .font(.caption)
                            .foregroundStyle(Color(asset: Asset.Icon.accent))
                    }
                }
                Spacer()
                Image(systemName: viewModel.noteContentImageName)
                    .foregroundStyle(viewModel.noteContentColor)
            }
            .font(.body)
            .listRowBackground(Color.clear)
            .contentShape(.rect)
        }
    }

}

extension NoteList.Row {

    struct ViewModel: Equatable, Identifiable {
        let id: UUID
        let original: String
        let translation: String
        let isVocabulary: Bool

        var isDone: Bool {
            !original.isEmpty && !translation.isEmpty
        }

        var categoryImageName: String {
            isVocabulary ? "textformat.abc" : "text.bubble.fill"
        }

        var noteContentImageName: String {
            if isDone {
                "checkmark.circle.fill"
            } else {
                original.isEmpty ? "k.circle" : "e.circle"
            }
        }

        var noteContentColor: Color {
            isDone
            ? Color(asset: Asset.Logo.Prominent.blue)
            : Color(asset: Asset.Logo.Muted.blue)
        }

        var noteContentLabel: String {
            original.isEmpty ? translation : original
        }

        var suggestLabel: String {
            if isVocabulary {
                original.isEmpty ? "단어를 알맞게 번역해보세요!" : "단어의 뜻을 찾아보세요!"
            } else {
                original.isEmpty ? "문장을 번역해보세요!" : "문장을 해석해보세요!"
            }
        }

    }

}
