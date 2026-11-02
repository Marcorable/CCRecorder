
import Foundation

public protocol ManagingConversationUsecase: Sendable {
    func conversations() async -> Result<[Conversation], DomainError>
    func conversation(id: Conversation.ID) async -> Result<Conversation?, DomainError>

    func notes(conversationID: Conversation.ID) async -> Result<[Note], DomainError>
    func update(_ conversation: Conversation) async throws
    func deleteConversations(_ conversations: [Conversation]) async -> Result<Void, DomainError>

    func addNote(
        content: String,
        to conversationID: Conversation.ID
    ) async throws -> Conversation
    func deleteNotes(
        ids: [Note.ID],
        from conversationID: Conversation.ID
    ) async throws -> Conversation
}

extension DomainError {

    public enum ManagingConversationUsecaseFailure: Error, Equatable, Sendable {
        case conversationNotFound
    }

}
