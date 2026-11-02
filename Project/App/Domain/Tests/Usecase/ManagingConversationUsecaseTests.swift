
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
        private var updateError: TestError?
        private var updated: Conversation?
        private var conversations: [Conversation] = []

        func create(_ conversation: Conversation) throws {}
        func read() throws -> [Conversation] { conversations }

        func read(id: Conversation.ID) throws -> Conversation? {
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
        }

        func delete(ids: [UUID]) throws {}

        func setReadError(_ error: TestError) {
            readError = error
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
    }

    actor NoteRepositorySpy: NoteRepository {
        private var notes: [Note] = []
        private var created: Note?
        private var deleted: [UUID] = []

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

        func delete(ids: [UUID]) {
            deleted = ids
        }

        func setNotes(_ notes: [Note]) {
            self.notes = notes
        }

        func createdNote() -> Note? {
            created
        }

        func deletedIDs() -> [UUID] {
            deleted
        }
    }

}
