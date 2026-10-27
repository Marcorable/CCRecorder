
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
        let now: @Sendable () -> Date
    }

}

extension ManagingConversationUsecaseConcrete: ManagingConversationUsecase {

    func notes(of conversation: Conversation) async -> Result<[Note], DomainError> {
        do {
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
        to conversation: Conversation
    ) async throws -> Conversation {
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
        from conversation: Conversation
    ) async throws -> Conversation {
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
