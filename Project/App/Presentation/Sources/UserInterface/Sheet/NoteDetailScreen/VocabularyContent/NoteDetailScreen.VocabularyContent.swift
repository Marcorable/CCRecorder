import SwiftUI

extension NoteDetailScreen {

    struct VocabularyContent: View {
        @Binding var original: String
        @Binding var translation: String

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
        }
    }

}

private extension NoteDetailScreen.VocabularyContent {

    struct InputField: View {
        let title: String
        let iconName: String
        @Binding var text: String

        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                HStack {
                    Image(systemName: iconName)
                        .foregroundStyle(Color(asset: Asset.Logo.Prominent.blue))
                    TextField(
                        title,
                        text: $text,
                        prompt: Text(title.components(separatedBy: " ")[0])
                    )
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

}

#Preview {
    @Previewable @State var original = "conversation"
    @Previewable @State var translation = "대화"

    NoteDetailScreen.VocabularyContent(
        original: $original,
        translation: $translation
    )
    .padding(.horizontal)
}
