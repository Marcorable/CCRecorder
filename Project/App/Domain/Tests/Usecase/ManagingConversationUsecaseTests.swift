
import Testing
import Foundation

@testable import Domain

@Suite("Conversation 관리")
struct ManagingConversationUsecaseTests {
    private let conversationRepository: ConversationRepositorySpy
    private let noteRepository: NoteRepositorySpy
    private let recordFileRepository: RecordFileRepositorySpy
    private let usecase: ManagingConversationUsecaseConcrete

    init() {
        let conversationRepository = ConversationRepositorySpy()
        let noteRepository = NoteRepositorySpy()
        let recordFileRepository = RecordFileRepositorySpy()
        self.conversationRepository = conversationRepository
        self.noteRepository = noteRepository
        self.recordFileRepository = recordFileRepository
        self.usecase = .init(
            dependency: .init(
                conversationRepository: conversationRepository,
                noteRepository: noteRepository,
                recordFileRepository: recordFileRepository,
                now: { Date(timeIntervalSince1970: 1_000) }
            )
        )
    }
}

private actor RecordFileRepositorySpy: RecordFileRepository {
    func makeRecordingURL() async throws -> URL {
        URL(fileURLWithPath: "/tmp/recording.m4a")
    }

    func fileURL(of fileName: String) async -> URL? {
        nil
    }

    func fileExists(at fileURL: URL) async -> Bool {
        false
    }

    func removeFile(at fileURL: URL) async throws {}
}

extension ManagingConversationUsecaseTests {

    @Test("ID에 해당하는 Conversation을 반환한다")
    func conversationReturnsMatchingConversation() async throws {
        // given
        let conversation = conversation()
        await conversationRepository.setConversations([conversation])

        // when
        let result = try await usecase.conversation(id: conversation.id).get()

        // then
        #expect(result == conversation)
    }

    @Test("Conversation 조회에 실패하면 Data 오류를 반환한다")
    func conversationReturnsDataErrorWhenRepositoryFails() async {
        // given
        await conversationRepository.setReadError(.failed)

        // when
        let result = await usecase.conversation(id: .init())

        // then
        guard case .failure(.data) = result else {
            Issue.record("Data 오류를 반환해야 합니다.")
            return
        }
    }

    @Test("Conversation의 Note ID 순서대로 Note를 반환한다")
    func notesReturnsConversationOrder() async throws {
        // given
        let first = Note(
            createdDate: .init(),
            original: "First",
            translation: "",
            category: .vocabulary
        )
        let second = Note(
            createdDate: .init(),
            original: "Second",
            translation: "",
            category: .vocabulary
        )
        await noteRepository.setNotes([second, first])
        let conversation = conversation(noteIds: [first.id, second.id])
        await conversationRepository.setConversations([conversation])

        // when
        let notes = try await usecase.notes(conversationID: conversation.id).get()

        // then
        #expect(notes.map(\.id) == [first.id, second.id])
    }

    @Test("영어 Note를 생성하고 Conversation에 연결한다")
    func addNoteCreatesEnglishNote() async throws {
        // given
        let conversation = conversation()
        await conversationRepository.setConversations([conversation])

        // when
        let updated = try await usecase.addNote(
            content: "Nice to meet you",
            to: conversation.id
        )

        // then
        let note = try #require(await noteRepository.createdNote())
        #expect(note.original == "Nice to meet you")
        #expect(note.translation.isEmpty)
        #expect(note.category == .sentence)
        #expect(note.createdDate == Date(timeIntervalSince1970: 1_000))
        #expect(updated.noteIds == [note.id])
        #expect(await conversationRepository.updatedConversation() == updated)
    }

    @Test("한글 Note를 번역 값으로 생성한다")
    func addNoteCreatesKoreanTranslation() async throws {
        // given
        let conversation = conversation()
        await conversationRepository.setConversations([conversation])

        // when
        _ = try await usecase.addNote(
            content: "반가워요",
            to: conversation.id
        )

        // then
        let note = try #require(await noteRepository.createdNote())
        #expect(note.original.isEmpty)
        #expect(note.translation == "반가워요")
        #expect(note.category == .vocabulary)
    }

    @Test("Conversation 연결에 실패하면 생성한 Note를 제거한다")
    func addNoteRemovesNoteWhenConversationUpdateFails() async {
        // given
        let conversation = conversation()
        await conversationRepository.setConversations([conversation])
        await conversationRepository.setUpdateError(.failed)

        // when
        do {
            _ = try await usecase.addNote(
                content: "Hello",
                to: conversation.id
            )
            Issue.record("Data 오류를 던져야 합니다.")
        } catch {
            // then
            let note = await noteRepository.createdNote()
            #expect(await noteRepository.deletedIDs() == [note?.id].compactMap { $0 })
        }
    }

    @Test("정보 수정은 최신 Note 연결을 유지한다")
    func updatePreservesLatestNoteReferences() async throws {
        // given
        let noteID = UUID()
        let stored = conversation(noteIds: [noteID])
        await conversationRepository.setConversations([stored])
        var editingItem = stored
        editingItem.title = "수정된 제목"
        editingItem.noteIds = []

        // when
        try await usecase.update(editingItem)

        // then
        let updated = try #require(await conversationRepository.updatedConversation())
        #expect(updated.title == "수정된 제목")
        #expect(updated.noteIds == [noteID])
    }

    @Test("존재하지 않는 Conversation 수정은 Usecase 오류를 유지한다")
    func updateMissingConversationThrowsUsecaseError() async {
        // given
        let conversation = conversation()

        // when, then
        do {
            try await usecase.update(conversation)
            Issue.record("Conversation 없음 오류를 던져야 합니다.")
        } catch DomainError.managingConversationUsecase(.conversationNotFound) {
        } catch {
            Issue.record("Usecase 오류를 그대로 전달해야 합니다.")
        }
    }

    @Test("Note를 삭제하면 Conversation 연결도 제거한다")
    func deleteNotesRemovesConversationReferences() async throws {
        // given
        let deletedID = UUID()
        let remainingID = UUID()
        let conversation = conversation(noteIds: [deletedID, remainingID])
        await conversationRepository.setConversations([conversation])

        // when
        let updated = try await usecase.deleteNotes(
            ids: [deletedID],
            from: conversation.id
        )

        // then
        #expect(updated.noteIds == [remainingID])
        #expect(await noteRepository.deletedIDs() == [deletedID])
        #expect(await conversationRepository.updatedConversation() == updated)
    }

    @Test("정보 수정과 Note 추가·삭제가 동시에 실행돼도 모든 변경을 유지한다")
    func concurrentMutationsPreserveEveryChange() async throws {
        // given
        let deletedID = UUID()
        let stored = conversation(noteIds: [deletedID])
        await conversationRepository.setConversations([stored])
        await conversationRepository.setReadDelay(.milliseconds(50))
        var editingItem = stored
        editingItem.title = "수정된 제목"
        editingItem.topic = "수정된 주제"

        // when
        async let update: Void = usecase.update(editingItem)
        async let addition = usecase.addNote(
            content: "Hello",
            to: stored.id
        )
        async let deletion = usecase.deleteNotes(
            ids: [deletedID],
            from: stored.id
        )
        _ = try await (update, addition, deletion)

        // then
        let createdID = try #require(await noteRepository.createdNote()?.id)
        let updated = try #require(
            await conversationRepository.storedConversation(id: stored.id)
        )
        #expect(updated.title == "수정된 제목")
        #expect(updated.topic == "수정된 주제")
        #expect(updated.noteIds == [createdID])
    }

    @Test("Note 삭제에 실패하면 Conversation 연결을 복원한다")
    func deleteNotesRestoresConversationWhenNoteDeletionFails() async throws {
        // given
        let noteID = UUID()
        let conversation = conversation(noteIds: [noteID])
        await conversationRepository.setConversations([conversation])
        await noteRepository.setDeleteError(.failed)

        // when
        do {
            _ = try await usecase.deleteNotes(
                ids: [noteID],
                from: conversation.id
            )
            Issue.record("Data 오류를 던져야 합니다.")
        } catch {
        }

        // then
        let restored = try #require(
            await conversationRepository.storedConversation(id: conversation.id)
        )
        #expect(restored.noteIds == [noteID])
    }

}

private extension ManagingConversationUsecaseTests {

    func conversation(noteIds: [UUID] = []) -> Conversation {
        .init(
            createdDate: .init(),
            pins: [],
            title: "Title",
            topic: "Topic",
            noteIds: noteIds,
            parties: []
        )
    }

    enum TestError: Error {
        case failed
    }

    actor ConversationRepositorySpy: ConversationRepository {
        private var readError: TestError?
        private var readDelay: Duration = .zero
        private var updateError: TestError?
        private var updated: Conversation?
        private var conversations: [Conversation] = []

        func create(_ conversation: Conversation) throws {}
        func read() throws -> [Conversation] { conversations }

        func read(id: Conversation.ID) async throws -> Conversation? {
            try await Task.sleep(for: readDelay)
            if let readError {
                throw readError
            }
            return conversations.first(where: { $0.id == id })
        }

        func update(_ conversation: Conversation) throws {
            if let updateError {
                throw updateError
            }
            updated = conversation
            guard let index = conversations.firstIndex(where: {
                $0.id == conversation.id
            }) else {
                return
            }
            conversations[index] = conversation
        }

        func delete(ids: [UUID]) throws {}

        func setReadError(_ error: TestError) {
            readError = error
        }

        func setReadDelay(_ delay: Duration) {
            readDelay = delay
        }

        func setUpdateError(_ error: TestError) {
            updateError = error
        }

        func setConversations(_ conversations: [Conversation]) {
            self.conversations = conversations
        }

        func updatedConversation() -> Conversation? {
            updated
        }

        func storedConversation(id: Conversation.ID) -> Conversation? {
            conversations.first(where: { $0.id == id })
        }
    }

    actor NoteRepositorySpy: NoteRepository {
        private var notes: [Note] = []
        private var created: Note?
        private var deleted: [UUID] = []
        private var deleteError: TestError?

        func create(_ note: Note) {
            created = note
        }

        func read() -> [Note] {
            notes
        }

        func read(id: Note.ID) -> Note? {
            notes.first(where: { $0.id == id })
        }

        func update(_ note: Note) throws {}

        func delete(ids: [UUID]) throws {
            if let deleteError {
                throw deleteError
            }
            deleted = ids
        }

        func setNotes(_ notes: [Note]) {
            self.notes = notes
        }

        func setDeleteError(_ error: TestError) {
            deleteError = error
        }

        func createdNote() -> Note? {
            created
        }

        func deletedIDs() -> [UUID] {
            deleted
        }
    }

}
