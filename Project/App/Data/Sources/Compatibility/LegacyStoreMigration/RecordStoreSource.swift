
import SwiftData
import Foundation

import Domain

enum RecordStoreSource {}

extension RecordStoreSource {

    @MainActor
    static func load(
        from storeURL: URL,
        schema: Schema
    ) throws -> LegacyStoreMigrationData {
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            configurations: configuration
        )
        let context = container.mainContext
        let conversations = try context.fetch(
            FetchDescriptor<Domain.Conversation.Record>()
        )
        let notes = try context.fetch(
            FetchDescriptor<Domain.Note.Record>()
        )
        let parties = try context.fetch(
            FetchDescriptor<Domain.Party.Record>()
        )

        return .init(
            conversations: conversations.map({ conversation in
                .init(
                    id: conversation.id,
                    createdDate: conversation.createdDate,
                    recordFileName: conversation.recordFileName,
                    pins: conversation.pins,
                    title: conversation.title,
                    topic: conversation.topic,
                    noteIds: conversation.noteIds,
                    parties: conversation.parties.map({ party in
                        .init(
                            id: party.id,
                            name: party.name
                        )
                    })
                )
            }),
            notes: notes.map({ note in
                .init(
                    id: note.id,
                    createdDate: note.createdDate,
                    original: note.original,
                    translation: note.translation,
                    category: note.category == .sentence
                        ? .sentence
                        : .vocabulary
                )
            }),
            parties: parties.map({ party in
                .init(
                    id: party.id,
                    name: party.name
                )
            }),
            recordSource: .currentDirectory
        )
    }

}
