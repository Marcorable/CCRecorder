
import Foundation

public struct Note: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let createdDate: Date
    public var original: String
    public var translation: String
    public var category: Category

    public init(
        id: UUID = .init(),
        createdDate: Date,
        original: String,
        translation: String,
        category: Category
    ) {
        self.id = id
        self.createdDate = createdDate
        self.original = original
        self.translation = translation
        self.category = category
    }

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
