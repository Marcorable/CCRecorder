
import SwiftUI
import SwiftData

import NavigationCoordinator

extension ConversationListScreen {

    struct Context: View {
        @Environment(Navigator<Screen>.self) private var navigator
        @Environment(\.modelContext) private var modelContext
        @Query(sort: \Conversation.createdDate) private var conversations: [Conversation]

        private let deletionService: ConversationDeletionService

        init(deletionService: ConversationDeletionService = .init()) {
            self.deletionService = deletionService
        }

        var body: some View {
            ConversationList(
                conversations: conversations,
                select: { navigator.push(.conversationDetail($0)) },
                onDelete: onDelete(at:)
            )
            .navigationTitle("Conversation")
        }
    }

}

extension ConversationListScreen.Context {

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
    ConversationListScreen.Context()
        .environment(Navigator<Screen>())
}
