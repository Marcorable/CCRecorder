
import Foundation

public protocol NoteRepository: Sendable {
    func create(_ note: Note) async throws
    func read() async throws -> [Note]
    func read(id: Note.ID) async throws -> Note?
    func update(_ note: Note) async throws
    func delete(ids: [UUID]) async throws
}
