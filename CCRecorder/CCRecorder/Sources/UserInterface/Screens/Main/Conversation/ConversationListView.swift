import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(ViewCoordinator.self) private var viewCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdDate) private var conversations: [Conversation]

    private let deletionService: ConversationDeletionService

    init(deletionService: ConversationDeletionService = .init()) {
        self.deletionService = deletionService
    }
    
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
            try? deletionService.delete(
                conversations[offset],
                from: modelContext
            )
        }
    }
    
}

#Preview {
    ConversationListView()
        .environment(ViewCoordinator())
}
