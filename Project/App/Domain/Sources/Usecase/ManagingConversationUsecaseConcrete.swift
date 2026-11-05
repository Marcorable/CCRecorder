
import Foundation

final class ManagingConversationUsecaseConcrete: Sendable {
    private let dependency: Dependency
    private let mutationLock = ConversationMutationLock()

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
        try await mutationLock.withLock(for: conversation.id) {
            do {
                guard var updatingItem = try await dependency.conversationRepository.read(
                    id: conversation.id
                ) else {
                    throw DomainError.managingConversationUsecase(.conversationNotFound)
                }
                updatingItem.title = conversation.title
                updatingItem.topic = conversation.topic
                updatingItem.parties = conversation.parties
                try await dependency.conversationRepository.update(updatingItem)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as DomainError {
                throw error
            } catch {
                throw DomainError.data(error)
            }
        }
    }

    func addNote(
        content: String,
        to conversationID: Conversation.ID
    ) async throws -> Conversation {
        try await mutationLock.withLock(for: conversationID) {
            guard var updatingItem = try await dependency.conversationRepository.read(
                id: conversationID
            ) else {
                throw DomainError.managingConversationUsecase(.conversationNotFound)
            }
            guard !content.isEmpty else {
                return updatingItem
            }

            let note = note(content: content)
            updatingItem.noteIds.append(note.id)
            do {
                try Task.checkCancellation()
                try await dependency.noteRepository.create(note)
                try Task.checkCancellation()
                try await dependency.conversationRepository.update(updatingItem)
                return updatingItem
            } catch {
                try? await dependency.noteRepository.delete(ids: [note.id])
                if error is CancellationError {
                    throw CancellationError()
                }
                throw DomainError.data(error)
            }
        }
    }

    func deleteNotes(
        ids: [Note.ID],
        from conversationID: Conversation.ID
    ) async throws -> Conversation {
        try await mutationLock.withLock(for: conversationID) {
            guard let conversation = try await dependency.conversationRepository.read(
                id: conversationID
            ) else {
                throw DomainError.managingConversationUsecase(.conversationNotFound)
            }
            guard !ids.isEmpty else {
                return conversation
            }

            let idSet = Set(ids)
            var updatingItem = conversation
            updatingItem.noteIds.removeAll(where: { idSet.contains($0) })
            do {
                try Task.checkCancellation()
                try await dependency.conversationRepository.update(updatingItem)
                try Task.checkCancellation()
                try await dependency.noteRepository.delete(ids: ids)
                return updatingItem
            } catch {
                try? await dependency.conversationRepository.update(conversation)
                if error is CancellationError {
                    throw CancellationError()
                }
                throw DomainError.data(error)
            }
        }
    }

}

private actor ConversationMutationLock {
    private var lockedIDs: Set<Conversation.ID> = []
    private var waiters: [Conversation.ID: [CheckedContinuation<Void, Never>]] = [:]

    func withLock<Value: Sendable>(
        for id: Conversation.ID,
        operation: @Sendable () async throws -> Value
    ) async rethrows -> Value {
        await lock(id)
        defer { unlock(id) }
        return try await operation()
    }

    private func lock(_ id: Conversation.ID) async {
        guard lockedIDs.contains(id) else {
            lockedIDs.insert(id)
            return
        }
        await withCheckedContinuation { continuation in
            waiters[id, default: []].append(continuation)
        }
    }

    private func unlock(_ id: Conversation.ID) {
        guard var queuedWaiters = waiters[id], !queuedWaiters.isEmpty else {
            lockedIDs.remove(id)
            waiters[id] = nil
            return
        }
        let continuation = queuedWaiters.removeFirst()
        waiters[id] = queuedWaiters.isEmpty ? nil : queuedWaiters
        continuation.resume()
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
