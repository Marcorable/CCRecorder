
import SwiftData
import Foundation

import Domain

@ModelActor
actor NoteRepositoryConcrete {}

extension NoteRepositoryConcrete: NoteRepository {

    func create(
        content: Note.Content,
        category: Note.Category
    ) async throws -> UUID {
        let record = Note.Record(
            content: content,
            category: category
        )
        do {
            modelContext.insert(record)
            try modelContext.save()
            return record.id
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func read() async throws -> [Note] {
        let records = try modelContext.fetch(FetchDescriptor<Note.Record>())
        let data = try JSONEncoder().encode(records)
        return try JSONDecoder().decode([Note].self, from: data)
    }

}

extension Note {

    @Model
    final class Record: Encodable {
        #Unique<Record>([\.id])

        var id: UUID
        var createdDate: Date
        var original: String
        var translation: String
        var category: Category

        init(
            id: UUID = .init(),
            createdDate: Date = .init(),
            content: Content,
            category: Category
        ) {
            self.id = id
            self.createdDate = createdDate
            self.category = category

            switch content {
                case .original(let original):
                    self.original = original
                    self.translation = ""

                case .translation(let translation):
                    self.original = ""
                    self.translation = translation
            }
        }
    }

}

extension Note.Record {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(original, forKey: .original)
        try container.encode(translation, forKey: .translation)
        try container.encode(category, forKey: .category)
    }

}

extension Note.Record {

    enum CodingKeys: String, CodingKey {
        case id
        case createdDate
        case original
        case translation
        case category
    }

}
