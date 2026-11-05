
import SwiftData
import Foundation

import Domain

@ModelActor
final actor NoteRepositoryConcrete {}

extension NoteRepositoryConcrete: NoteRepository {

    func create(_ note: Note) async throws {
        let record = Note.Record(note)
        do {
            modelContext.insert(record)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func read() async throws -> [Note] {
        let records = try modelContext.fetch(FetchDescriptor<Note.Record>())
        return records.map(note(from:))
    }

    func read(id: Note.ID) async throws -> Note? {
        let descriptor = FetchDescriptor<Note.Record>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first.map(note(from:))
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

private extension NoteRepositoryConcrete {

    func note(from record: Note.Record) -> Note {
        .init(
            id: record.id,
            createdDate: record.createdDate,
            original: record.original,
            translation: record.translation,
            category: record.category
        )
    }

}

extension Note {

    @Model
    final class NoteRecord {
        #Unique<NoteRecord>([\.id])

        var id: UUID
        var createdDate: Date
        var original: String
        var translation: String
        var category: Category

        init(_ note: Note) {
            self.id = note.id
            self.createdDate = note.createdDate
            self.original = note.original
            self.translation = note.translation
            self.category = note.category
        }
    }

    typealias Record = NoteRecord

}
