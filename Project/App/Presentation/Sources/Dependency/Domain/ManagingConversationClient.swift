
import Foundation

import Domain
import ComposableArchitecture

@DependencyClient
struct ManagingConversationClient: Sendable {
    var conversations: @Sendable () async -> Result<[Conversation], DomainError> = { .success([]) }
    var conversation: @Sendable (Conversation.ID) async -> Result<Conversation?, DomainError> = { _ in .success(nil) }
    var notes: @Sendable (Conversation.ID) async -> Result<[Note], DomainError> = { _ in .success([]) }
    var update: @Sendable (Conversation) async throws -> Void
    var deleteConversations: @Sendable ([Conversation]) async -> Result<Void, DomainError> = { _ in .success(()) }
    var addNote: @Sendable (String, Conversation.ID) async throws -> Conversation
    var deleteNotes: @Sendable ([Note.ID], Conversation.ID) async throws -> Conversation
}

extension ManagingConversationClient {

    init(usecase: ManagingConversationUsecase) {
        self.init(
            conversations: { await usecase.conversations() },
            conversation: { await usecase.conversation(id: $0) },
            notes: { await usecase.notes(conversationID: $0) },
            update: { try await usecase.update($0) },
            deleteConversations: { await usecase.deleteConversations($0) },
            addNote: { try await usecase.addNote(content: $0, to: $1) },
            deleteNotes: { try await usecase.deleteNotes(ids: $0, from: $1) }
        )
    }

    static let preview: Self = .init(
        conversations: { .success([]) },
        conversation: { _ in .success(nil) },
        notes: { _ in .success([]) },
        update: { _ in },
        deleteConversations: { _ in .success(()) },
        addNote: { _, _ in
            .init(
                createdDate: .init(),
                pins: [],
                title: "",
                topic: "",
                parties: []
            )
        },
        deleteNotes: { _, _ in
            .init(
                createdDate: .init(),
                pins: [],
                title: "",
                topic: "",
                parties: []
            )
        }
    )

}

extension DependencyValues {

    @DependencyEntry(
        previewValue: ManagingConversationClient.preview
    )
    var managingConversationUsecase: ManagingConversationClient = .init()

}
