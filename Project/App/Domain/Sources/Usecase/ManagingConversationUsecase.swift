
import Foundation

public protocol ManagingConversationUsecase: Sendable {
    func conversations() async -> Result<[Conversation], DomainError>

    func notes(of conversation: Conversation) async -> Result<[Note], DomainError>
    func update(_ conversation: Conversation) async throws
    func deleteConversations(_ conversations: [Conversation]) async -> Result<Void, DomainError>

    func addNote(
        content: String,
        to conversation: Conversation
    ) async throws -> Conversation
    func deleteNotes(
        ids: [Note.ID],
        from conversation: Conversation
    ) async throws -> Conversation
}
