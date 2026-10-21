
import SwiftUI
import Combine

extension NoteDetailScreen {

    struct VocabularyContent: View {
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
                InputField(
                    title: "단어 Original",
                    iconName: "e.circle.fill",
                    text: $original
                )
                Spacer()
                InputField(
                    title: "번역 Translation",
                    iconName: "k.circle.fill",
                    text: $translation
                )
                Spacer()
            }
            .onChange(of: original, initial: false) { _, newValue in
                textSubject.send((newValue, translation))
            }
            .onChange(of: translation, initial: false) { _, newValue in
                textSubject.send((original, newValue))
            }
        }
    }

}

extension NoteDetailScreen.VocabularyContent {

    fileprivate struct InputField: View {
        let title: String
        @State var iconName: String
        @State var text: Binding<String>

        var body: some View {
            Group {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    HStack {
                        Image(systemName: iconName)
                            .foregroundStyle(Color.Logo.Prominent.blue)
                        TextField(
                            title,
                            text: text,
                            prompt: Text(title.components(separatedBy: " ")[0])
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }

}

#Preview {
    NoteDetailScreen.VocabularyContent(
        textSubject: .init(
            (
                original: "conversation",
                translation: "대화"
            )
        )
    )
    .padding(.horizontal)
}
