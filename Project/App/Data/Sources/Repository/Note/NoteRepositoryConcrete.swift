
import SwiftData
import Foundation

import Domain

@ModelActor
public actor NoteRepositoryConcrete {}

extension NoteRepositoryConcrete: NoteRepository {

    public func create(
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
