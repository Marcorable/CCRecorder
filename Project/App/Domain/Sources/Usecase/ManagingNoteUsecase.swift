
import Foundation

public protocol ManagingNoteUsecase: Sendable {
    func loadNotes() async -> Result<[Note], DomainError>
    func updateNote(_ note: Note) async -> Result<Void, DomainError>
    func deleteNotes(ids: [UUID]) async -> Result<Void, DomainError>
}
