
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
        let original = Note(
            createdDate: .init(),
            original: "Hello",
            translation: "",
            category: .sentence
        )
        let translation = Note(
            createdDate: .init(),
            original: "",
            translation: "사과",
            category: .vocabulary
        )
        try await repository.create(original)
        try await repository.create(translation)

        // when
        let notes = try await repository.read()

        // then
        let originalNote = try #require(
            notes.first(where: { $0.id == original.id })
        )
        #expect(originalNote.original == "Hello")
        #expect(originalNote.translation.isEmpty)
        #expect(originalNote.category == .sentence)

        let translationNote = try #require(
            notes.first(where: { $0.id == translation.id })
        )
        #expect(translationNote.original.isEmpty)
        #expect(translationNote.translation == "사과")
        #expect(translationNote.category == .vocabulary)
    }

    @Test("Note를 수정하면 변경된 값을 반환한다")
    func updateChangesNote() async throws {
        // given
        var note = Note(
            createdDate: .init(),
            original: "Hello",
            translation: "",
            category: .vocabulary
        )
        try await repository.create(note)
        note.original = "Hello, world"
        note.translation = "안녕, 세상"
        note.category = .sentence

        // when
        try await repository.update(note)

        // then
        let updatedNote = try #require(
            try await repository.read().first(where: { $0.id == note.id })
        )
        #expect(updatedNote.original == "Hello, world")
        #expect(updatedNote.translation == "안녕, 세상")
        #expect(updatedNote.category == .sentence)
    }

    @Test("선택한 Note를 삭제하면 목록에서 제거한다")
    func deleteRemovesSelectedNotes() async throws {
        // given
        let deleted = Note(
            createdDate: .init(),
            original: "Deleted",
            translation: "",
            category: .vocabulary
        )
        let remaining = Note(
            createdDate: .init(),
            original: "Remaining",
            translation: "",
            category: .vocabulary
        )
        try await repository.create(deleted)
        try await repository.create(remaining)

        // when
        try await repository.delete(ids: [deleted.id])

        // then
        let notes = try await repository.read()
        #expect(!notes.contains(where: { $0.id == deleted.id }))
        #expect(notes.contains(where: { $0.id == remaining.id }))
    }

}
