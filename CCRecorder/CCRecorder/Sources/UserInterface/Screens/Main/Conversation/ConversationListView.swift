
import SwiftUI
import SwiftData

import NavigationCoordinator

struct ConversationListView: View {
    @Environment(Navigator<Screen>.self) private var navigator
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
                                navigator.push(.conversationDetail(conversation))
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
        .environment(Navigator<Screen>())
}
