import SwiftUI

struct NoteListRow: View {
    let note: Note
    
    var body: some View {
        HStack {
            Image(systemName: categoryImageName)
                .foregroundStyle(Color.Light.logoRed)
                .frame(width: 36, alignment: .center)
            
            VStack(alignment: .leading) {
                if note.isDone {
                    Text(note.original)
                    Text(note.translation)
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text(noteContentLabel)
                    Text(suggestLabel)
                        .font(.caption)
                        .foregroundColor(.Any.icon)
                }
            }
            Spacer()
            Image(systemName: noteContentImageName)
                .foregroundStyle(noteContentColor)
        }
        .font(.body)
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
    }
    
}

private extension NoteListRow {

    var isOriginalEmpty: Bool {
        note.original.isEmpty
    }
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
        note.isDone ? .Light.logoBlue : .Dark.logoBlue
    }
    var noteContentLabel: String {
        isOriginalEmpty ? note.translation : note.original
    }
    var suggestLabel: String {
        switch note.category {
            case .vocabulary:       isOriginalEmpty ? "단어를 알맞게 번역해보세요!" : "단어의 뜻을 찾아보세요!"
            case .sentence:         isOriginalEmpty ? "문장을 번역해보세요!" : "문장을 해석해보세요!"
        }
    }
    
}

#if DEBUG
#Preview("영어만 문장") {
    NoteListRow(note: .originalOnlySentenceNote)
}

#Preview("한글만 단어") {
    NoteListRow(note: .translationOnlyVocabularyNote)
}

fileprivate extension Note {
    
    static var originalOnlySentenceNote: Self {
        .init(
            original: "Nice to meet you.",
            translation: "",
            category: .sentence
        )
    }
    
    static var translationOnlyVocabularyNote: Self {
        .init(
            original: "",
            translation: "한국말 문장만 있는 노트",
            category: .vocabulary
        )
    }
    
}
#endif
