
import Foundation

public protocol ManagingConversationUsecase: Sendable {
    func notes(of conversation: Conversation) async -> Result<[Note], DomainError>
    func update(_ conversation: Conversation) async throws
    func addNote(
        content: String,
        to conversation: Conversation
    ) async throws -> Conversation
    func deleteNotes(
        ids: [Note.ID],
        from conversation: Conversation
    ) async throws -> Conversation
}
