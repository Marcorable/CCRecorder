
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

    func update(_ note: Note) async throws {
        let id = note.id
        let descriptor = FetchDescriptor<Note.Record>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            return
        }
        record.original = note.original
        record.translation = note.translation
        record.category = note.category
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func delete(ids: [UUID]) async throws {
        guard !ids.isEmpty else {
            return
        }
        let idSet = Set(ids)
        let records = try modelContext.fetch(FetchDescriptor<Note.Record>())
        records
            .filter { idSet.contains($0.id) }
            .forEach(modelContext.delete)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

}

extension Note {

    @Model
    final class Record {
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

extension Note.Record: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(original, forKey: .original)
        try container.encode(translation, forKey: .translation)
        try container.encode(category, forKey: .category)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdDate
        case original
        case translation
        case category
    }

}
