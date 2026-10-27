
import Foundation

public protocol ManagingNoteUsecase: Sendable {
    func loadNotes() async -> Result<[Note], DomainError>
    func updateNote(_ note: Note) async -> Result<Void, DomainError>
    func deleteNotes(ids: [UUID]) async -> Result<Void, DomainError>
}

#if DEBUG
public final class FakeManagingNoteUsecase: ManagingNoteUsecase {

    public init() {}

    public func loadNotes() async -> Result<[Note], DomainError> {
        .success([])
    }

    public func updateNote(_ note: Note) async -> Result<Void, DomainError> {
        .success(())
    }

    public func deleteNotes(ids: [UUID]) async -> Result<Void, DomainError> {
        .success(())
    }

}
#endif
