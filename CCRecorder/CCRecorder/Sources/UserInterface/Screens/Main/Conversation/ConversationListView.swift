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
