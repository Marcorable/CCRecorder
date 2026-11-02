
import SwiftUI

import Domain

extension ConversationDetailScreen.NoteList {

    struct Row: View {
        let note: Note

        var body: some View {
            HStack {
                Image(systemName: categoryImageName)
                    .foregroundStyle(Color(asset: Asset.Logo.Prominent.red))
                    .frame(
                        width: 36,
                        alignment: .center
                    )
                VStack(alignment: .leading) {
                    if note.isDone {
                        Text(note.original)
                        Text(note.translation)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        Text(noteContentLabel)
                        Text(suggestLabel)
                            .font(.caption)
                            .foregroundStyle(Color(asset: Asset.Icon.accent))
                    }
                }
                Spacer()
                Image(systemName: noteContentImageName)
                    .foregroundStyle(noteContentColor)
            }
            .font(.body)
            .listRowBackground(Color.clear)
            .contentShape(.rect)
        }
    }

}

private extension ConversationDetailScreen.NoteList.Row {

    var isOriginalEmpty: Bool { note.original.isEmpty }

    var categoryImageName: String {
        note.category == .sentence ? "text.bubble.fill" : "textformat.abc"
    }

    var noteContentImageName: String {
        if note.isDone {
            "checkmark.circle.fill"
        } else {
            isOriginalEmpty ? "k.circle" : "e.circle"
        }
    }

    var noteContentColor: Color {
        note.isDone
            ? Color(asset: Asset.Logo.Prominent.blue)
            : Color(asset: Asset.Logo.Muted.blue)
    }

    var noteContentLabel: String {
        isOriginalEmpty ? note.translation : note.original
    }

    var suggestLabel: String {
        switch note.category {
            case .vocabulary:
                isOriginalEmpty ? "단어를 알맞게 번역해보세요!" : "단어의 뜻을 찾아보세요!"

            case .sentence:
                isOriginalEmpty ? "문장을 번역해보세요!" : "문장을 해석해보세요!"
        }
    }

}
