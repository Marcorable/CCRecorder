
import Foundation

final class ManagingConversationUsecaseConcrete: Sendable {
    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}
extension ManagingConversationUsecaseConcrete {

    struct Dependency: Sendable {
        let conversationRepository: ConversationRepository
        let noteRepository: NoteRepository
        let recordFileRepository: RecordFileRepository
        let now: @Sendable () -> Date
    }

}

extension ManagingConversationUsecaseConcrete: ManagingConversationUsecase {

    func conversations() async -> Result<[Conversation], DomainError> {
        do {
            return .success(try await dependency.conversationRepository.read())
        } catch {
            return .failure(.data(error))
        }
    }

    func conversation(id: Conversation.ID) async -> Result<Conversation?, DomainError> {
        do {
            return .success(try await dependency.conversationRepository.read(id: id))
        } catch {
            return .failure(.data(error))
        }
    }

    func deleteConversations(
        _ conversations: [Conversation]
    ) async -> Result<Void, DomainError> {
        do {
            for conversation in conversations {
                if let fileURL = await dependency.recordFileRepository.fileURL(
                    of: conversation.recordFileName
                ), await dependency.recordFileRepository.fileExists(at: fileURL) {
                    try await dependency.recordFileRepository.removeFile(at: fileURL)
                }
            }
            try await dependency.conversationRepository.delete(
                ids: conversations.map(\.id)
            )
            return .success(())
        } catch {
            return .failure(.data(error))
        }
    }

    func notes(
        conversationID: Conversation.ID
    ) async -> Result<[Note], DomainError> {
        do {
            guard let conversation = try await dependency.conversationRepository.read(
                id: conversationID
            ) else {
                return .failure(.managingConversationUsecase(.conversationNotFound))
            }
            let notes = try await dependency.noteRepository.read()
            let notesByID = Dictionary(
                uniqueKeysWithValues: notes.map { ($0.id, $0) }
            )
            return .success(
                conversation.noteIds.compactMap { notesByID[$0] }
            )
        } catch {
            return .failure(.data(error))
        }
    }

    func update(_ conversation: Conversation) async throws {
        do {
            try await dependency.conversationRepository.update(conversation)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw DomainError.data(error)
        }
    }

    func addNote(
        content: String,
        to conversationID: Conversation.ID
    ) async throws -> Conversation {
        guard let conversation = try await dependency.conversationRepository.read(
            id: conversationID
        ) else {
            throw DomainError.managingConversationUsecase(.conversationNotFound)
        }
        guard !content.isEmpty else {
            return conversation
        }

        let note = note(content: content)
        var updatedConversation = conversation
        updatedConversation.noteIds.append(note.id)

        do {
            try Task.checkCancellation()
            try await dependency.noteRepository.create(note)
            try Task.checkCancellation()
            try await dependency.conversationRepository.update(updatedConversation)
            return updatedConversation
        } catch {
            try? await dependency.noteRepository.delete(ids: [note.id])
            if error is CancellationError {
                throw CancellationError()
            }
            throw DomainError.data(error)
        }
    }

    func deleteNotes(
        ids: [Note.ID],
        from conversationID: Conversation.ID
    ) async throws -> Conversation {
        guard let conversation = try await dependency.conversationRepository.read(
            id: conversationID
        ) else {
            throw DomainError.managingConversationUsecase(.conversationNotFound)
        }
        guard !ids.isEmpty else {
            return conversation
        }

        let idSet = Set(ids)
        var updatedConversation = conversation
        updatedConversation.noteIds.removeAll { idSet.contains($0) }

        do {
            try Task.checkCancellation()
            try await dependency.conversationRepository.update(updatedConversation)
            try Task.checkCancellation()
            try await dependency.noteRepository.delete(ids: ids)
            return updatedConversation
        } catch {
            try? await dependency.conversationRepository.update(conversation)
            if error is CancellationError {
                throw CancellationError()
            }
            throw DomainError.data(error)
        }
    }

}

private extension ManagingConversationUsecaseConcrete {

    func note(content: String) -> Note {
        let particleCount = content.components(separatedBy: " ").count
        let category: Note.Category = particleCount > 2
            ? .sentence
            : .vocabulary

        switch language(of: content) {
            case .english:
                return .init(
                    createdDate: dependency.now(),
                    original: content,
                    translation: "",
                    category: category
                )

            case .korean, .mixed:
                return .init(
                    createdDate: dependency.now(),
                    original: "",
                    translation: content,
                    category: category
                )
        }
    }

    func language(of content: String) -> Language {
        let isKorean = content.range(
            of: "[가-힣]",
            options: .regularExpression
        ) != nil
        let isEnglish = content.range(
            of: "[A-Za-z]",
            options: .regularExpression
        ) != nil

        if isKorean && isEnglish {
            return .mixed
        } else if isKorean {
            return .korean
        } else {
            return .english
        }
    }

    enum Language {
        case korean
        case english
        case mixed
    }

}
