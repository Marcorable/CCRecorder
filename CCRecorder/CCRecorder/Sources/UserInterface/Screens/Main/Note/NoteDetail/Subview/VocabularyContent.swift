import SwiftUI
import Combine

struct VocabularyContent: View {
    @State private var original: String
    @State private var translation: String
    
    let textSubject: NoteTextSubject
    
    init(textSubject: NoteTextSubject) {
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
                        .foregroundStyle(Color.Light.logoBlue)
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
