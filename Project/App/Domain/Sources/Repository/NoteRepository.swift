
import Foundation

public protocol NoteRepository: Sendable {
    func create(
        content: Note.Content,
        category: Note.Category
    ) async throws -> UUID

    func read() async throws -> [Note]

    func update(_ note: Note) async throws

    func delete(ids: [UUID]) async throws
}

extension Note {

    public enum Content: Sendable {
        case original(String)
        case translation(String)
    }

}
