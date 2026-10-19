import SwiftUI

struct ConversationInfoBox: View {
    @Binding var title: String
    @Binding var topic: String
    @Binding var parties: [Party]
    
    @State private var partyName: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        GroupBox {
            if isEditing {
                TextField(
                    "InputTitle",
                    text: $title,
                    prompt: Text("녹음 제목을 입력하세요")
                )
                .trailingAction(
                    of: !title.isEmpty,
                    label: {
                        Image(systemName: "multiply.circle.fill")
                            .accessibilityLabel("입력 내용 지우기")
                    },
                    action: {
                        title = ""
                    }
                )
                .multilineTextAlignment(.center)
                .cornerRadius(10)
                TextField(
                    "InputTopic",
                    text: $topic,
                    prompt: Text("대화 주제를 입력하세요")
                )
                .trailingAction(
                    of: !topic.isEmpty,
                    label: {
                        Image(systemName: "multiply.circle.fill")
                            .accessibilityLabel("입력 내용 지우기")
                    },
                    action: {
                        topic = ""
                    }
                )
                .multilineTextAlignment(.center)
                .cornerRadius(10)
                TextField(
                    "InputParties",
                    text: $partyName,
                    prompt: Text("참여자를 추가하세요")
                )
                .trailingAction(
                    of: !partyName.isEmpty,
                    label: {
                        Image(systemName: "multiply.circle.fill")
                            .accessibilityLabel("입력 내용 지우기")
                    },
                    action: {
                        partyName = ""
                    }
                )
                .multilineTextAlignment(.center)
                .cornerRadius(10)
                .onSubmit(add)
                if !parties.isEmpty {
                    ScrollView(.horizontal, showsIndicators: true) {
                        LazyHGrid(rows: [.init(.flexible())]) {
                            ForEach(parties.indices, id: \.self) { index in
                                HStack {
                                    Text(randomEmoji)
                                    Text(parties[index].name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Button(
                                        action: { delete(of: index) },
                                        label: {
                                            Image(systemName: "delete.backward")
                                                .foregroundStyle(Color.Light.logoRed)
                                        }
                                    )
                                }
                                .padding()
                                .background(Color.Surface.recorderProminent)
                                .clipShape(.rect(cornerRadius: 15))
                            }
                        }
                        .frame(height: 32, alignment: .center)
                        .padding()
                    }
                }
            }
            Button(
                action: {
                    withAnimation { isEditing.toggle() }
                },
                label: {
                    HStack {
                        Text("Conversation Information")
                            .font(.headline)
                            .foregroundStyle(.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.accent)
                            .rotationEffect(.degrees(isEditing ? -90.0 : 0.0))
                    }
                }
            )
        }
        .preferredColorScheme(.dark)
        .padding()
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button(
                        action: {
                            UIApplication.shared
                                .sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                        },
                        label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    )
                    Spacer()
                }
            }
        }
    }
    
}

private extension ConversationInfoBox {
    
    var randomEmoji: String {
        let emoji = "😀😃😄😁😆🥹😂🤣😊☺️🙂😉😌😍😘🥰🥳😙😚😋😛😝🤓😎🥸🤩🤭🤗🤠"
        return .init(Array(emoji)[Int.random(in: 0..<emoji.count)])
    }
    
    func add() {
        guard !partyName.isEmpty else { return  }
        parties.insert(.init(name: partyName), at: 0)
        partyName.removeAll()
    }
    
    func delete(of index: Int) {
        parties.remove(at: index)
    }
    
}
