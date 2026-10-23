
import SwiftUI

import ComposableArchitecture

extension RecordScreen {

    struct ConversationInfoBox: View {
        @Bindable var store: StoreOf<ConversationInfoBox.Feature>

        var body: some View {
            GroupBox {
                if store.isEditing {
                    TextField(
                        "InputTitle",
                        text: $store.title,
                        prompt: Text("녹음 제목을 입력하세요")
                    )
                    .trailingAction(
                        of: !store.title.isEmpty,
                        label: {
                            Image(systemName: "multiply.circle.fill")
                                .accessibilityLabel("입력 내용 지우기")
                        },
                        action: {
                            store.send(.view(.clearTitleButtonTapped))
                        }
                    )
                    .multilineTextAlignment(.center)
                    .cornerRadius(10)
                    TextField(
                        "InputTopic",
                        text: $store.topic,
                        prompt: Text("대화 주제를 입력하세요")
                    )
                    .trailingAction(
                        of: !store.topic.isEmpty,
                        label: {
                            Image(systemName: "multiply.circle.fill")
                                .accessibilityLabel("입력 내용 지우기")
                        },
                        action: {
                            store.send(.view(.clearTopicButtonTapped))
                        }
                    )
                    .multilineTextAlignment(.center)
                    .cornerRadius(10)
                    TextField(
                        "InputParties",
                        text: $store.partyName,
                        prompt: Text("참여자를 추가하세요")
                    )
                    .trailingAction(
                        of: !store.partyName.isEmpty,
                        label: {
                            Image(systemName: "multiply.circle.fill")
                                .accessibilityLabel("입력 내용 지우기")
                        },
                        action: {
                            store.send(.view(.clearPartyNameButtonTapped))
                        }
                    )
                    .multilineTextAlignment(.center)
                    .cornerRadius(10)
                    .onSubmit {
                        store.send(.view(.addParty))
                    }
                    if !store.parties.isEmpty {
                        ScrollView(.horizontal, showsIndicators: true) {
                            LazyHGrid(rows: [.init(.flexible())]) {
                                ForEach(store.parties.indices, id: \.self) { index in
                                    HStack {
                                        Text(randomEmoji)
                                        Text(store.parties[index])
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Button(
                                            action: {
                                                store.send(.view(.removePartyButtonTapped(index)))
                                            },
                                            label: {
                                                Image(systemName: "delete.backward")
                                                    .foregroundStyle(Color.Logo.Prominent.red)
                                            }
                                        )
                                    }
                                    .padding()
                                    .background(Color.Surface.Recorder.prominent)
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
                        withAnimation {
                            _ = store.send(.view(.editingButtonTapped))
                        }
                    },
                    label: {
                        HStack {
                            Text("Conversation Information")
                                .font(.headline)
                                .foregroundStyle(.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.accent)
                                .rotationEffect(.degrees(store.isEditing ? -90.0 : 0.0))
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

}

private extension RecordScreen.ConversationInfoBox {

    var randomEmoji: String {
        let emoji = "😀😃😄😁😆🥹😂🤣😊☺️🙂😉😌😍😘🥰🥳😙😚😋😛😝🤓😎🥸🤩🤭🤗🤠"
        return .init(Array(emoji)[Int.random(in: 0..<emoji.count)])
    }

}

#Preview {
    Color.Surface.Recorder.muted.overlay {
        RecordScreen.ConversationInfoBox(
            store: .init(
                initialState: .init(
                    title: "영어 회화",
                    topic: "여행",
                    parties: ["Marco"],
                    isEditing: true
                ),
                reducer: { RecordScreen.ConversationInfoBox.Feature() }
            )
        )
    }
}
