//
//  ConversationInfo.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct ConversationInfo: View {
    @Binding var inputTitle: String
    @Binding var inputTopic: String
    @Binding var inputMember: String
    @Binding var members: [Member]
    
    @State private var isEditing: Bool = false
    
    var body: some View {
        GroupBox {
            if isEditing {
                TextField(
                    "InputTitle",
                    text: $inputTitle,
                    prompt: Text("녹음 제목을 입력하세요")
                ) // InputTitle
                .multilineTextAlignment(.center)
                .showClearButton($inputTitle)
                .cornerRadius(10)
                
                TextField(
                    "InputTopic",
                    text: $inputTopic,
                    prompt: Text("대화 주제를 입력하세요")
                ) // InputTopic
                .multilineTextAlignment(.center)
                .showClearButton($inputTopic)
                .cornerRadius(10)
                
                TextField(
                    "InputMembers",
                    text: $inputMember,
                    prompt: Text("참여자를 추가하세요")
                ) // InputMemebers
                .multilineTextAlignment(.center)
                .showClearButton($inputMember)
                .cornerRadius(10)
                .onSubmit {
                    guard inputMember.count > 0 else { return  }
                    let randomEmoji = randomEmoji()
                    self.members.insert(.init(name: inputMember, emoji: randomEmoji), at: 0)
                    self.inputMember = ""
                }
                if members.count > 0 {
                    ScrollView(.horizontal, showsIndicators: true) {
                        let rows = [ GridItem(.fixed(30)) ]
                        LazyHGrid(rows: rows) {
                            ForEach(members, id: \.name) { member in
                                ZStack {
                                    Rectangle()
                                        .cornerRadius(15)
                                        .foregroundColor(.darkRecordColor)
                                    HStack {
                                        Text(member.emoji)
                                        Text(member.name)
                                            .font(.headline)
                                        Button(
                                            action: {
                                                guard let index = members.firstIndex(of: member) else {
                                                    return
                                                }
                                                members.remove(at: index)
                                            }, label: {
                                                Image(systemName: "delete.backward")
                                                    .foregroundColor(.logoLightRed)
                                            }
                                        )
                                    }
                                    .padding()
                                }
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
                }, label: {
                    HStack {
                        Text("Conversation Information")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.logoDarkGreen)
                            .rotationEffect(.degrees(isEditing ? -90.0 : 0.0))
                    }
                }
            )
            .tint(.ccTintColor)
        }
        .padding()
    }
    
}

extension ConversationInfo {
    
    private func randomEmoji() -> String {
        let emoji = "😀😃😄😁😆🥹😂🤣😊☺️🙂😉😌😍😘🥰🥳😙😚😋😛😝🤓😎🥸🤩🤭🤗🤠"
            .map({ String($0) }).randomElement()!
        return emoji
    }
    
}

#if DEBUG
#Preview {
    ConversationInfo(
        inputTitle: .constant(""),
        inputTopic: .constant(""),
        inputMember: .constant(""),
        members: .constant(Member.previewList)
    )
}
#endif
