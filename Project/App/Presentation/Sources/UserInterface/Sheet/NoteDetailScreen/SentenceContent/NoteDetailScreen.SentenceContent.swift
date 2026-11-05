
import SwiftUI

extension NoteDetailScreen {

    struct SentenceContent: View {
        @Binding var original: String
        @Binding var translation: String

        var body: some View {
            VStack(alignment: .leading) {
                InputField(
                    title: "문장 Original",
                    iconName: "e.circle.fill",
                    text: $original
                )
                InputField(
                    title: "번역 Translation",
                    iconName: "k.circle.fill",
                    text: $translation
                )
            }
        }
    }

}

private extension NoteDetailScreen.SentenceContent {

    struct InputField: View {
        @Environment(\.colorScheme) private var colorScheme

        let title: String
        let iconName: String
        @Binding var text: String

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundStyle(Color(asset: Asset.Logo.Prominent.blue))
                    Text(title)
                }
                TextEditor(text: $text)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(
                        Color(
                            asset: colorScheme == .dark
                            ? Asset.Surface.Background.primary
                            : Asset.Surface.Background.grouped
                        )
                        .clipShape(.rect(cornerRadius: 15))
                    )
            }
        }
    }

}

#Preview("InputField") {
    @Previewable @State var text = "This is a sentence."

    NoteDetailScreen.SentenceContent.InputField(
        title: "문장 Original",
        iconName: "e.circle.fill",
        text: $text
    )
    .padding(.horizontal)
}

#Preview {
    @Previewable @State var original = "This is a sentence."
    @Previewable @State var translation = "문장입니다."

    NoteDetailScreen.SentenceContent(
        original: $original,
        translation: $translation
    )
    .padding(.horizontal)
}
