
import Testing

import Data
import Domain

@Suite("Note 저장소", .serialized)
@MainActor
struct NoteRepositoryConcreteTests {
    private let repository: any NoteRepository

    init() throws {
        try DataFactory.setup(true)
        self.repository = DataFactory.makeNoteRepository()
    }
}
extension NoteRepositoryConcreteTests {

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

}
