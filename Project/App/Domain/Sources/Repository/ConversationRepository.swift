
import Foundation

public protocol ConversationRepository: Sendable {
    func create(_ conversation: Conversation) async throws
    func read() async throws -> [Conversation]
    func update(_ conversation: Conversation) async throws
    func delete(ids: [UUID]) async throws
}
