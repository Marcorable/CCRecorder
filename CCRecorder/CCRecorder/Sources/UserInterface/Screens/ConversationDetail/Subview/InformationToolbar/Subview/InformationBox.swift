//
//  InformationBox.swift
//  CCRecorder
//
//  Created by 김용우 on 9/11/24.
//

import SwiftUI
import Combine

struct InformationBox: View {
    @Binding var conversation: Conversation
    @Binding var isEditing: Bool
    let focuseField: FocusState<ConversationDetailField?>.Binding
    let topicSubject: CurrentValueSubject<String, Never>
    
    init(
        conversation: Binding<Conversation>,
        isEditing: Binding<Bool>,
        focuseField: FocusState<ConversationDetailField?>.Binding,
        topicSubject: CurrentValueSubject<String, Never>
    ) {
        self._conversation = conversation
        self.topic = topicSubject.value
        self._isEditing = isEditing
        self.focuseField = focuseField
        self.topicSubject = topicSubject
    }
    
    @State private var topic: String
    @State private var party: String = ""
    
    var body: some View {
        GroupBox {
            Button(
                action: {
                    withAnimation {
                        isEditing.toggle()
                    }
                }, label: {
                    HStack {
                        Text("Conversation Information")
                            .font(.headline)
                        Spacer()
                        if isEditing {
                            Text("완료")
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.Dark.logoGreen)
                            .rotationEffect(.degrees(isEditing ? 90.0 : 0.0))
                    }
                }
            )
            if isEditing {
                VStack {
                    HStack {
                        Text("주제")
                            .font(.body)
                            .fontWeight(.bold)
                        TextField(
                            "Topic",
                            text: $topic,
                            prompt: Text("주제를 입력하세요")
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                    .focused(focuseField, equals: .infoTopic)
                    HStack {
                        Text("참여")
                            .font(.body)
                            .fontWeight(.bold)
                        TextField(
                            "Party",
                            text: $party,
                            prompt: Text("참여인원을 추가하세요 (공백 분리)")
                        )
                        .textFieldStyle(.roundedBorder)
                        Button(
                            action: {
                                withAnimation {
                                    addParty()
                                }
                            },
                            label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .padding(.leading)
                            }
                        )
                    }
                    .focused(focuseField, equals: .infoParty)
                    if !conversation.parties.isEmpty {
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(alignment: .center) {
                                Text("\(conversation.parties.count)명")
                                    .font(.body)
                                    .fontWeight(.bold)
                                LazyHGrid(rows: [.init(.flexible())]) {
                                    ForEach(conversation.parties, id: \.id) { party in
                                        HStack(spacing: 6) {
                                            Text(party.name)
                                            Button(
                                                action: { delete(of: party) },
                                                label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(Color.Light.logoRed)
                                                }
                                            )
                                        }
                                        .padding(6)
                                        .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
        }
        .padding([.leading, .trailing])
        .onChange(of: topic) {
            topicSubject.send($1)
        }
    }
}

private extension InformationBox {
    
    func addParty() {
        conversation.parties.append(.init(name: party))
        party = ""
    }
    
    func delete(of party: Party) {
        if let index = conversation.parties.firstIndex(where: { $0.id == party.id }) {
            conversation.parties.remove(at: index)
        }
    }
    
}
