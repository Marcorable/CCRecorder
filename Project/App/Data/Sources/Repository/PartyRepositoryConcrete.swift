
import SwiftData
import Foundation

import Domain

@ModelActor
actor PartyRepositoryConcrete {}

extension PartyRepositoryConcrete: PartyRepository {

    func create(_ party: Party) async throws {
        let record = Party.Record(party)
        do {
            modelContext.insert(record)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func read() async throws -> [Party] {
        let records = try modelContext.fetch(FetchDescriptor<Party.Record>())
        return records.map({ record in
            Party(
                id: record.id,
                name: record.name,
                isAvailable: true
            )
        })
    }

    func update(_ party: Party) async throws {
        let id = party.id
        let descriptor = FetchDescriptor<Party.Record>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            return
        }
        record.name = party.name
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
        let records = try modelContext.fetch(FetchDescriptor<Party.Record>())
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

extension Party {

    @Model
    final class PartyRecord {
        #Unique<PartyRecord>([\.id])

        var id: UUID
        var name: String

        init(_ party: Party) {
            self.id = party.id
            self.name = party.name
        }
    }

    typealias Record = PartyRecord

}
