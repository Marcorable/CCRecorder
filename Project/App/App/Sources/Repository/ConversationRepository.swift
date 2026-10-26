
import Foundation

@MainActor
protocol ConversationRepository {
    func save(_ conversation: Conversation) throws
}

#if DEBUG
@MainActor
final class MockConversationRepository: ConversationRepository {
    var conversations: [Conversation] = []
    var error: Error?

    func save(_ conversation: Conversation) throws {
        if let error {
            throw error
        }
        conversations.append(conversation)
    }
}
#endif
