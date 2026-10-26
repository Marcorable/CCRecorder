
import SwiftData
import Foundation

import Domain

@MainActor
public struct NoteRepositoryConcrete {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}

extension NoteRepositoryConcrete: NoteRepository {

    public func create(
        content: Note.Content,
        category: Note.Category
    ) async throws -> UUID {
        let model = Note.Model(
            content: content,
            category: category
        )
        do {
            modelContext.insert(model)
            try modelContext.save()
            return model.id
        } catch {
            modelContext.rollback()
            throw error
        }
    }

}

extension Note {

    @Model
    final class Model {
        #Unique<Model>([\.id])

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
