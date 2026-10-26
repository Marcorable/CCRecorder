
import Foundation

public struct Note: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let createdDate: Date
    public var original: String
    public var translation: String
    public var category: Category

    public enum Category: String, Codable, Sendable {
        case vocabulary
        case sentence
    }

}

extension Note {

    public var isDone: Bool {
        !original.isEmpty && !translation.isEmpty
    }

}
