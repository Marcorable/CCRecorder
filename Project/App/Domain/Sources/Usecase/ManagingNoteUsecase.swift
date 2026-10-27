
import Foundation

public protocol ManagingNoteUsecase: Sendable {
    func loadNotes() async -> Result<[Note], DomainError>
    func deleteNotes(ids: [UUID]) async -> Result<Void, DomainError>
}
