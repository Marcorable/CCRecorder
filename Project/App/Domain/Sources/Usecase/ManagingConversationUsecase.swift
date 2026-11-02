
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

#if DEBUG
public final class FakeManagingConversationUsecase: ManagingConversationUsecase, @unchecked Sendable {
    public var conversations: [Conversation]
    public var loadResult: Result<[Conversation], DomainError>?
    public var deleteResult: Result<Void, DomainError>?

    public init(conversations: [Conversation] = []) {
        self.conversations = conversations
    }

    public func conversations() async -> Result<[Conversation], DomainError> {
        loadResult ?? .success(conversations)
    }

    public func deleteConversations(
        _ conversations: [Conversation]
    ) async -> Result<Void, DomainError> {
        if let deleteResult {
            return deleteResult
        }
        let ids = Set(conversations.map(\.id))
        self.conversations.removeAll(where: { ids.contains($0.id) })
        return .success(())
    }

    public func notes(of conversation: Conversation) async -> Result<[Note], DomainError> {
        .success([])
    }

    public func update(_ conversation: Conversation) async throws {}

    public func addNote(
        content: String,
        to conversation: Conversation
    ) async throws -> Conversation {
        conversation
    }

    public func deleteNotes(
        ids: [Note.ID],
        from conversation: Conversation
    ) async throws -> Conversation {
        conversation
    }
}
#endif
