
import SwiftData
import Foundation

import Domain

@ModelActor
actor ConversationRepositoryConcrete {}

extension ConversationRepositoryConcrete: ConversationRepository {

    func create(_ conversation: Conversation) async throws {
        let record = Conversation.Record(conversation)
        do {
            modelContext.insert(record)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func read() async throws -> [Conversation] {
        let records = try modelContext.fetch(
            FetchDescriptor<Conversation.Record>()
        )
        let partyRecords = try modelContext.fetch(
            FetchDescriptor<Party.Record>()
        )
        let partiesById = Dictionary(
            uniqueKeysWithValues: partyRecords.map({ ($0.id, $0) })
        )
        return records.map({ record in
            let parties = record.parties.map({ snapshot in
                let party = partiesById[snapshot.id]
                return Party(
                    id: snapshot.id,
                    name: party?.name ?? snapshot.name,
                    isAvailable: party != nil
                )
            })
            return Conversation(
                id: record.id,
                createdDate: record.createdDate,
                recordFileName: record.recordFileName,
                pins: record.pins,
                title: record.title,
                topic: record.topic,
                noteIds: record.noteIds,
                parties: parties
            )
        })
    }

    func update(_ conversation: Conversation) async throws {
        let id = conversation.id
        let descriptor = FetchDescriptor<Conversation.Record>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            return
        }
        record.recordFileName = conversation.recordFileName
        record.pins = conversation.pins
        record.title = conversation.title
        record.topic = conversation.topic
        record.noteIds = conversation.noteIds
        record.parties = conversation.parties.map(Conversation.Record.PartySnapshot.init)
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
        let records = try modelContext.fetch(
            FetchDescriptor<Conversation.Record>()
        )
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

extension Conversation {

    @Model
    final class ConversationRecord {
        #Unique<ConversationRecord>([\.id])

        var id: UUID
        var createdDate: Date
        var recordFileName: String
        var pins: [TimeInterval]
        var title: String
        var topic: String
        var noteIds: [UUID]
        var parties: [PartySnapshot]

        init(_ conversation: Conversation) {
            self.id = conversation.id
            self.createdDate = conversation.createdDate
            self.recordFileName = conversation.recordFileName
            self.pins = conversation.pins
            self.title = conversation.title
            self.topic = conversation.topic
            self.noteIds = conversation.noteIds
            self.parties = conversation.parties.map(PartySnapshot.init)
        }

        struct PartySnapshot: Codable {
            let id: UUID
            let name: String

            init(_ party: Party) {
                self.id = party.id
                self.name = party.name
            }
        }
    }

    typealias Record = ConversationRecord

}
