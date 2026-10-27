import SwiftUI

extension NoteDetailScreen {

    struct SentenceContent: View {
        @Environment(\.colorScheme) private var colorScheme

        @Binding var original: String
        @Binding var translation: String

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "e.circle.fill")
                        .foregroundStyle(Color(asset: Asset.Logo.Prominent.blue))
                    Text("문장 Original")
                }
                TextEditor(text: $original)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(textEditorBackground)

                HStack {
                    Image(systemName: "k.circle.fill")
                        .foregroundStyle(Color(asset: Asset.Logo.Prominent.blue))
                    Text("번역 Translation")
                }
                TextEditor(text: $translation)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(textEditorBackground)
            }
        }

        private var textEditorBackground: some View {
            let color = colorScheme == .dark
                ? Asset.Surface.Background.primary
                : Asset.Surface.Background.grouped
            return Color(asset: color)
                .clipShape(.rect(cornerRadius: 15))
        }
    }

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
