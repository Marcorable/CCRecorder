//
//  ConversationList.swift
//  CCRecorder
//
//  Created by 김용우 on 9/9/24.
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(ViewCoordinator.self) private var viewCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdDate) private var conversations: [Conversation]
    
    var body: some View {
        List {
            ForEach(conversations, id: \.id) { conversation in
                ConversationListRow(conversation: conversation)
                    .onTapGesture {
                        viewCoordinator.push(.conversationDetail(conversation))
                    }
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: onDelete(at:))
        }
        .listStyle(.plain)
        .navigationTitle("Conversation")
        .toolbar { // FIXME: 더미 데이터
            ToolbarItem(placement: .principal) {
                Button(
                    action: {
                        modelContext.insert(
                            Conversation(
                                id: .init(),
                                createdDate: .init(),
                                recordFilePath: .init(string: "http://www.naver.com")!,
                                title: "Dummy \(conversations.count + 1)",
                                topic: "Dummy \(conversations.count + 1)",
                                parties: (0...3).map { .init(name: "Dummy \($0)") }
                            )
                        )
                    }, label: { Text("더미 추가") }
                )
            }
        }
    }
    
}

extension ConversationListView {
    
    private func onDelete(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(conversations[offset])
            // TODO: RecordFile 제거 기능 추가
        }
    }
    
}

#Preview {
    ConversationListView()
        .environment(ViewCoordinator())
}
