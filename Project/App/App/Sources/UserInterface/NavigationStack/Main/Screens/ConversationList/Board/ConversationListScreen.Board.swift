
import SwiftUI

extension ConversationListScreen {

    struct Board: View {
        let conversations: [Conversation]
        let select: (Conversation) -> Void
        let onDelete: (IndexSet) -> Void

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
                            Row(conversation: conversation)
                                .onTapGesture {
                                    select(conversation)
                                }
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: onDelete)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

}

#if DEBUG
#Preview {
    ConversationListScreen.Board(
        conversations: [.preview],
        select: { _ in },
        onDelete: { _ in }
    )
}
#endif
