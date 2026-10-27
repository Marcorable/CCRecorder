
import Testing
import Foundation

@testable import Domain

@Suite("Note 관리")
struct ManagingNoteUsecaseTests {
    private let repository: MockNoteRepository
    private let usecase: any ManagingNoteUsecase

    init() {
        let repository = MockNoteRepository()
        self.repository = repository
        self.usecase = ManagingNoteUsecaseConcrete(
            dependency: .init(noteRepository: repository)
        )
    }
}

extension ManagingNoteUsecaseTests {

    @Test("저장된 Note 목록을 불러온다")
    func loadNotesReturnsRepositoryNotes() async {
        // given
        let note = Note(
            createdDate: .init(),
            original: "Hello",
            translation: "안녕",
            category: .vocabulary
        )
        await repository.setNotes([note])

        // when
        let result = await usecase.loadNotes()

        // then
        switch result {
            case .success(let notes):
                #expect(notes == [note])

            case .failure:
                Issue.record("저장된 Note 목록을 반환해야 합니다.")
        }
    }

    @Test("Note 목록을 불러오지 못하면 Data 오류를 반환한다")
    func loadNotesReturnsDataError() async {
        // given
        await repository.setError(.failed)

        // when
        let result = await usecase.loadNotes()

        // then
        switch result {
            case .success:
                Issue.record("Data 오류를 반환해야 합니다.")

            case .failure(.data(let error)):
                #expect(error is TestError)
        }
    }

    @Test("선택한 Note를 삭제한다")
    func deleteNotesForwardsIds() async throws {
        // given
        let ids = [UUID(), UUID()]

        // when
        let result = await usecase.deleteNotes(ids: ids)

        // then
        try result.get()
        #expect(await repository.deletedIds() == ids)
    }

}

private extension ManagingNoteUsecaseTests {

    enum TestError: Error {
        case failed
    }

    actor MockNoteRepository: NoteRepository {
        private var notes: [Note] = []
        private var error: TestError?
        private var deleted: [UUID] = []

        func create(_ note: Note) throws {
            if let error {
                throw error
            }
        }

        func read() throws -> [Note] {
            if let error {
                throw error
            }
            return notes
        }

        func update(_ note: Note) throws {
            if let error {
                throw error
            }
        }

        func delete(ids: [UUID]) throws {
            if let error {
                throw error
            }
            deleted = ids
        }

        func setNotes(_ notes: [Note]) {
            self.notes = notes
        }

        func setError(_ error: TestError) {
            self.error = error
        }

        func deletedIds() -> [UUID] {
            deleted
        }
    }

}
