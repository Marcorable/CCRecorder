
import Testing
import Foundation

@testable import Domain

@Suite("Conversation 관리")
struct ManagingConversationUsecaseTests {
    private let conversationRepository: ConversationRepositorySpy
    private let noteRepository: NoteRepositorySpy
    private let usecase: ManagingConversationUsecaseConcrete

    init() {
        let conversationRepository = ConversationRepositorySpy()
        let noteRepository = NoteRepositorySpy()
        self.conversationRepository = conversationRepository
        self.noteRepository = noteRepository
        self.usecase = .init(
            dependency: .init(
                conversationRepository: conversationRepository,
                noteRepository: noteRepository,
                now: { Date(timeIntervalSince1970: 1_000) }
            )
        )
    }
}

extension ManagingConversationUsecaseTests {

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

        // when
        let notes = try await usecase.notes(of: conversation).get()

        // then
        #expect(notes.map(\.id) == [first.id, second.id])
    }

    @Test("영어 Note를 생성하고 Conversation에 연결한다")
    func addNoteCreatesEnglishNote() async throws {
        // given
        let conversation = conversation()

        // when
        let updated = try await usecase.addNote(
            content: "Nice to meet you",
            to: conversation
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
        // when
        _ = try await usecase.addNote(
            content: "반가워요",
            to: conversation()
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
        await conversationRepository.setError(.failed)

        // when
        do {
            _ = try await usecase.addNote(
                content: "Hello",
                to: conversation()
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

        // when
        let updated = try await usecase.deleteNotes(
            ids: [deletedID],
            from: conversation
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
        private var error: TestError?
        private var updated: Conversation?

        func create(_ conversation: Conversation) throws {}
        func read() throws -> [Conversation] { [] }

        func update(_ conversation: Conversation) throws {
            if let error {
                throw error
            }
            updated = conversation
        }

        func delete(ids: [UUID]) throws {}

        func setError(_ error: TestError) {
            self.error = error
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
