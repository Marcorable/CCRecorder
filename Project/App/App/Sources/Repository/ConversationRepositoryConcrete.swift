
import SwiftData

@MainActor
struct ConversationRepositoryConcrete {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}

extension ConversationRepositoryConcrete: ConversationRepository {

    func save(_ conversation: Conversation) throws {
        do {
            modelContext.insert(conversation)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

}

#if DEBUG
extension ModelContext {

    static var mock: ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Conversation.self, Note.self, Party.self,
            configurations: configuration
        )
        return .init(container)
    }

}
#endif
