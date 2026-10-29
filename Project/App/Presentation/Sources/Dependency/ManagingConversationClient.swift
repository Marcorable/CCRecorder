
import Foundation

import Domain
import ComposableArchitecture

@DependencyClient
struct ManagingConversationClient: Sendable {
    var conversations: @Sendable () async -> Result<[Conversation], DomainError> = { .success([]) }
    var notes: @Sendable (Conversation) async -> Result<[Note], DomainError> = { _ in .success([]) }
    var update: @Sendable (Conversation) async throws -> Void
    var deleteConversations: @Sendable ([Conversation]) async -> Result<Void, DomainError> = { _ in .success(()) }
    var addNote: @Sendable (String, Conversation) async throws -> Conversation
    var deleteNotes: @Sendable ([Note.ID], Conversation) async throws -> Conversation
}

extension ManagingConversationClient {

    init(usecase: ManagingConversationUsecase) {
        self.init(
            conversations: { await usecase.conversations() },
            notes: { await usecase.notes(of: $0) },
            update: { try await usecase.update($0) },
            deleteConversations: { await usecase.deleteConversations($0) },
            addNote: { try await usecase.addNote(content: $0, to: $1) },
            deleteNotes: { try await usecase.deleteNotes(ids: $0, from: $1) }
        )
    }

}

extension ManagingConversationClient: TestDependencyKey {

    static let previewValue = Self(usecase: FakeManagingConversationUsecase())
    static let testValue = Self()

}

extension DependencyValues {

    var managingConversationUsecase: ManagingConversationClient {
        get { self[ManagingConversationClient.self] }
        set { self[ManagingConversationClient.self] = newValue }
    }

}
