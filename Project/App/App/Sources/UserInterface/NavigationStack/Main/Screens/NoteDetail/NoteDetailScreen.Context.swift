
import SwiftUI
import Combine
import SwiftData

extension NoteDetailScreen {

    struct Context: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.modelContext) private var modelContext

        @Query private var notes: [Note]

        let note: Note

        private let textSubject: TextSubject
        @State private var isEdited: Bool = false
        @State private var isPrsentedAlert: Bool = false

        init(note: Note) {
            self.note = note
            self.textSubject = .init((note.original, note.translation))
        }

        var body: some View {
            NavigationView {
                VStack(alignment: .leading) {
                    switch note.category {
                        case .vocabulary:   VocabularyContent(textSubject: textSubject)
                        case .sentence:     SentenceContent(textSubject: textSubject)
                    }
                }
                .padding(.horizontal)
                .toolbar {
                    Toolbar(
                        isEdited: $isEdited,
                        isVocabulary: note.category == .vocabulary,
                        saveAction: { dismiss() }
                    )
                }
            }
            .onReceive(
                textSubject
                    .dropFirst()
                    .handleEvents(receiveOutput: { _ in isEdited = true })
                    .debounce(for: 1, scheduler: RunLoop.main)
                    .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            ) { _ in
                updateNote()
            }
            .onDisappear {
                if isEdited {
                    updateNote()
                }
            }
        }
    }

}

extension NoteDetailScreen.Context {

    private var isEmpty: Bool {
        textSubject.value.original.isEmpty && textSubject.value.translation.isEmpty
    }

    private func updateNote() {
        if let index = notes.firstIndex(of: note), !isEmpty {
            let original = textSubject.value.original
            let translation = textSubject.value.translation

            notes[index].original = original
            notes[index].translation = translation
            let originalParticleCount = original.components(separatedBy: " ").count
            let translationParticleCount = translation.components(separatedBy: " ").count
            let isSentence = originalParticleCount > 2 || translationParticleCount > 2
            notes[index].category = isSentence ? .sentence : .vocabulary
            do {
                try modelContext.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}

extension NoteDetailScreen.Context {

    struct Toolbar: ToolbarContent {
        @Binding var isEdited: Bool
        let isVocabulary: Bool
        let saveAction: () -> Void

        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: imageSystemName)
                        .foregroundStyle(Color.Logo.Prominent.red)
                    Text(title)
                        .font(.headline)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button (
                    action: saveAction,
                    label: {
                        Text("저장")
                            .font(.headline)
                            .tint(.Logo.Muted.green)
                    }
                )
                .disabled(!isEdited)
                .opacity(isEdited ? 1 : 0.3)
            }
        }
    }

}

extension NoteDetailScreen.Context.Toolbar {

    private var title: String               {
        isVocabulary ? "Vocabulary" : "Sentense"
    }
    private var imageSystemName: String     {
        isVocabulary ? "textformat.abc" : "text.bubble.fill"
    }

}

#if DEBUG
#Preview("Vocabulary") {
    NoteDetailScreen.Context(note: .vocabularyDummy)
}
#Preview("Sentence") {
    NoteDetailScreen.Context(note: .sentenceDummy)
}

extension Note {

    static var vocabularyDummy: Self {
        .init(
            original: "Test",
            translation: "",
            category: .vocabulary
        )
    }
    static var sentenceDummy: Self {
        .init(
            original: "",
            translation: "테스트 용 문장을 이렇게 작성함",
            category: .sentence
        )
    }

}
#endif
