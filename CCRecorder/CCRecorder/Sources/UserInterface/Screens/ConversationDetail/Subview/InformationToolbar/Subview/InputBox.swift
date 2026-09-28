import SwiftUI

struct InputBox: View {
    @Environment(\.modelContext) var modelContext
    @Binding var conversation: Conversation
    let focuseField: FocusState<ConversationDetailField?>.Binding
    
    @State private var inputText: String = ""
    
    var body: some View {
        GroupBox {
            HStack {
                TextField(
                    "Input Text",
                    text: $inputText,
                    prompt: Text("영어 또는 한글 메모를 작성하세요")
                )
                .textFieldStyle(.roundedBorder)
                .showClearButton($inputText)
                .focused(focuseField, equals: .inputNote)
                .onSubmit(addNote)
                Button(
                    action: addNote,
                    label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .padding(.leading)
                    }
                )
            }
        }
        .padding(.horizontal)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(
                    action: {
                        UIApplication.shared
                            .sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                    }, label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                )
                Spacer()
                Button(
                    action: addNote,
                    label: {
                        Text("추가")
                    }
                )
            }
        }
    }
    
}

private extension InputBox {
    
    func addNote() {
        guard !inputText.isEmpty else {
            return
        }
        let newNote: Note
        let particleCount = inputText.components(separatedBy: " ").count
        let category: Note.Category = particleCount > 2 ? .sentence : .vocabulary
        switch check(of: inputText) {
            case .english:
                newNote = .init(
                    original: inputText,
                    translation: "",
                    category: category
                )
                
            case .korean:
                fallthrough
            
            case .mixed:
                newNote = .init(
                    original: "",
                    translation: inputText,
                    category: category
                )
                
        }
        withAnimation {
            modelContext.insert(newNote)
            conversation.noteIds.append(newNote.id)
            inputText = ""
        }
    }
    
    func check(of text: String) -> Language {
        let isKorean = text.range(of: "[가-힣]", options: .regularExpression) != nil
        let isEnglish = text.range(of: "[A-Za-z]", options: .regularExpression) != nil
        
        if isKorean && isEnglish {
            return .mixed
        } else if isKorean {
            return .korean
        } else {
            return .english
        }
    }
    
}
