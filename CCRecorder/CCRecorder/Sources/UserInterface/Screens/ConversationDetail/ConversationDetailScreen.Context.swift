
import SwiftUI
import SwiftData

extension ConversationDetailScreen {

    struct Context: View {
        @Environment(\.modelContext) private var modelContext
        @Query(sort: \Conversation.createdDate) private var conversations: [Conversation]
        @Query(sort: \Note.createdDate, order: .reverse) private var notes: [Note]

        @State var conversation: Conversation
        @State private var player = AudioPlayer()

        var body: some View {
            VStack {
                Editor(conversation: $conversation)
                NoteList(
                    notes: filteredNotes,
                    onDelete: onDelete(of:)
                )
                PlaybackPanel(
                    player: player,
                    filePath: RecordFileStore().fileURL(of: conversation.recordFileName),
                    pins: conversation.pins
                )
            }
            .onChange(of: conversation, initial: false) {
                update(of: $1)
            }
        }
    }

}

extension ConversationDetailScreen.Context {

    private var filteredNotes: [Note] {
        notes.filter { note in
            conversation.noteIds.contains(where: { $0 == note.id })
        }
    }

    private func onDelete(of indexSet: IndexSet) {
        for noteId in indexSet.map({ conversation.noteIds[$0] }) {
            if let note = notes.first(where: { $0.id == noteId }) {
                modelContext.delete(note)
            }
        }
        conversation.noteIds.remove(atOffsets: indexSet)
    }

    private func update(of newValue: Conversation) {
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
    ConversationDetailScreen.Context(conversation: .preview)
}

extension Conversation {

    static var preview: Self {
        .init(
            recordFileName: "",
            title: "제목",
            topic: "주제",
            parties: (0...3).map { .init(name: "name \($0)") }
        )
    }

}
#endif
