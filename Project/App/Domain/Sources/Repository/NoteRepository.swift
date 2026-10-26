
import Foundation

public protocol NoteRepository: Sendable {
    func create(
        content: Note.Content,
        category: Note.Category
    ) async throws -> UUID
}

extension Note {

    public enum Content: Sendable {
        case original(String)
        case translation(String)
    }

}
