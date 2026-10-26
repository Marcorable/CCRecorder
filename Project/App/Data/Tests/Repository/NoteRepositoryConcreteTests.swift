
import Testing

import Data
import Domain

extension DataRepositoryTests {

    @Suite("Note 저장소")
    @MainActor
    struct NoteRepositoryConcreteTests {
        private let repository: any NoteRepository

        init() throws {
            try DataFactory.setup(true)
            self.repository = DataFactory.makeNoteRepository()
        }
    }

}

extension DataRepositoryTests.NoteRepositoryConcreteTests {

    @Test("저장된 Note가 없으면 빈 목록을 반환한다")
    func readReturnsEmptyWhenNoNoteExists() async throws {
        // when
        let notes = try await repository.read()

        // then
        #expect(notes.isEmpty)
    }

    @Test("저장한 Record를 Domain Note로 반환한다")
    func readReturnsCreatedNotes() async throws {
        // given
        let originalId = try await repository.create(
            content: .original("Hello"),
            category: .sentence
        )
        let translationId = try await repository.create(
            content: .translation("사과"),
            category: .vocabulary
        )

        // when
        let notes = try await repository.read()

        // then
        let original = try #require(notes.first { $0.id == originalId })
        #expect(original.original == "Hello")
        #expect(original.translation.isEmpty)
        #expect(original.category == .sentence)

        let translation = try #require(notes.first { $0.id == translationId })
        #expect(translation.original.isEmpty)
        #expect(translation.translation == "사과")
        #expect(translation.category == .vocabulary)
    }

    @Test("Note를 수정하면 변경된 값을 반환한다")
    func updateChangesNote() async throws {
        // given
        let id = try await repository.create(
            content: .original("Hello"),
            category: .vocabulary
        )
        var note = try #require(
            try await repository.read().first { $0.id == id }
        )
        note.original = "Hello, world"
        note.translation = "안녕, 세상"
        note.category = .sentence

        // when
        try await repository.update(note)

        // then
        let updatedNote = try #require(
            try await repository.read().first { $0.id == id }
        )
        #expect(updatedNote.original == "Hello, world")
        #expect(updatedNote.translation == "안녕, 세상")
        #expect(updatedNote.category == .sentence)
    }

    @Test("선택한 Note를 삭제하면 목록에서 제거한다")
    func deleteRemovesSelectedNotes() async throws {
        // given
        let deletedId = try await repository.create(
            content: .original("Deleted"),
            category: .vocabulary
        )
        let remainingId = try await repository.create(
            content: .original("Remaining"),
            category: .vocabulary
        )

        // when
        try await repository.delete(ids: [deletedId])

        // then
        let notes = try await repository.read()
        #expect(!notes.contains { $0.id == deletedId })
        #expect(notes.contains { $0.id == remainingId })
    }

}
