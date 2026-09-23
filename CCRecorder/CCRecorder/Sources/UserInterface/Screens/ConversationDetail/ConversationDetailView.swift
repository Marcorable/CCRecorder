import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdDate) private var conversations: [Conversation]
    @Query(sort: \Note.createdDate, order: .reverse) private var notes: [Note]

    @State var conversation: Conversation
    
    var body: some View {
        VStack {
            InformationToolbar(conversation: $conversation)
            NoteList(
                notes: filteredNotes,
                onDelete: onDelete(of:)
            )
            PlayTab()
        }
        .onChange(of: conversation, initial: false) {
            update(of: $1)
        }
    }
    
}

private extension ConversationDetailView {
    
    var filteredNotes: [Note] {
        notes.filter { note in
            conversation.noteIds.contains(where: { $0 == note.id })
        }
    }
    
    func onDelete(of indexSet: IndexSet) {
        for noteId in indexSet.map({ conversation.noteIds[$0] }) {
            if let note = notes.first(where: { $0.id == noteId }) {
                modelContext.delete(note)
            }
        }
        conversation.noteIds.remove(atOffsets: indexSet)
    }
    
    func update(of newValue: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == newValue.id }) {
            conversations[index].title = newValue.title
            conversations[index].topic = newValue.topic
            conversations[index].noteIds = newValue.noteIds
            conversations[index].parties = newValue.parties
        }
    }
    
}

#if DEBUG
#Preview {
    ConversationDetailView(conversation: .preview)
}

extension Conversation {
    
    static var preview: Self {
        .init(
            recordFilePath: .init(string: "")!,
            title: "제목",
            topic: "주제",
            parties: (0...3).map { .init(name: "name \($0)") }
        )
    }
    
}
#endif
