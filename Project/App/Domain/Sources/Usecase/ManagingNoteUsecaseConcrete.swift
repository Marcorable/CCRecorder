
import Foundation

final class ManagingNoteUsecaseConcrete: Sendable {
    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

extension ManagingNoteUsecaseConcrete {

    struct Dependency: Sendable {
        let noteRepository: any NoteRepository
    }

}

extension ManagingNoteUsecaseConcrete: ManagingNoteUsecase {

    func loadNotes() async -> Result<[Note], DomainError> {
        do {
            return .success(try await dependency.noteRepository.read())
        } catch {
            return .failure(.data(error))
        }
    }

    func updateNote(_ note: Note) async -> Result<Void, DomainError> {
        do {
            try await dependency.noteRepository.update(note)
            return .success(())
        } catch {
            return .failure(.data(error))
        }
    }

    func deleteNotes(ids: [UUID]) async -> Result<Void, DomainError> {
        do {
            try await dependency.noteRepository.delete(ids: ids)
            return .success(())
        } catch {
            return .failure(.data(error))
        }
    }

}
