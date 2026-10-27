
import SwiftUI
import Combine

extension NoteDetailScreen {

    struct SentenceContent: View {
        @Environment(\.colorScheme) private var colorScheme

        @State private var original: String
        @State private var translation: String

        let textSubject: TextSubject

        init(textSubject: TextSubject) {
            self.original = textSubject.value.original
            self.translation = textSubject.value.translation
            self.textSubject = textSubject
        }

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "e.circle.fill")
                        .foregroundStyle(Color.Logo.Prominent.blue)
                    Text("문장 Original")
                }
                TextEditor(text: $original)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(textEditorBackground)

                HStack {
                    Image(systemName: "k.circle.fill")
                        .foregroundStyle(Color.Logo.Prominent.blue)
                    Text("번역 Translation")
                }
                TextEditor(text: $translation)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(textEditorBackground)
            }
            .onChange(of: original, initial: false) { _, newValue in
                textSubject.send((newValue, translation))
            }
            .onChange(of: translation, initial: false) { _, newValue in
                textSubject.send((original, newValue))
            }
        }

        private var textEditorBackground: some View {
            (colorScheme == .dark ? Color.Surface.Background.primary : Color.Surface.Background.grouped)
                .cornerRadius(15)
        }
    }

}

#Preview {
    NoteDetailScreen.SentenceContent(textSubject: .init((original: "translation", translation: "번역")))
        .padding(.horizontal)
}
