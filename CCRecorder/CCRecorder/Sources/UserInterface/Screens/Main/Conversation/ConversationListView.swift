import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(ViewCoordinator.self) private var viewCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdDate) private var conversations: [Conversation]
    
    var body: some View {
        Group {
            if conversations.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "waveform",
                    description: Text("Record a conversation to see it here.")
                )
            } else {
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
            }
        }
        .navigationTitle("Conversation")
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
