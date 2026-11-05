
import SwiftData
import Foundation

enum LegacyV2Store {
    static let schema = Schema(
        [
            Conversation.self,
            Note.self,
            Party.self
        ]
    )
}

extension LegacyV2Store {

    @Model
    final class Conversation {
        #Unique<Conversation>([\.id])

        var id: UUID
        var createdDate: Date
        var recordFileName: String = ""
        var pins: [TimeInterval]
        var title: String
        var topic: String
        var noteIds: [UUID]
        @Relationship var parties: [Party]

        init(
            id: UUID = .init(),
            createdDate: Date = .init(),
            recordFileName: String,
            pins: [TimeInterval] = [],
            title: String,
            topic: String,
            notes: [UUID] = [],
            parties: [Party]
        ) {
            self.id = id
            self.createdDate = createdDate
            self.recordFileName = recordFileName
            self.pins = pins
            self.title = title
            self.topic = topic
            self.noteIds = notes
            self.parties = parties
        }
    }

    @Model
    final class Note {
        #Unique<Note>([\.id])

        var id: UUID
        var createdDate: Date
        var original: String
        var translation: String
        var category: Category

        init(
            id: UUID = .init(),
            createdDate: Date = .init(),
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

        enum Category: Codable {
            case vocabulary
            case sentence
        }
    }

    @Model
    final class Party {
        #Unique<Party>([\.id])

        var id: UUID
        var name: String

        init(
            id: UUID = .init(),
            name: String
        ) {
            self.id = id
            self.name = name
        }
    }

}

extension LegacyV2Store {

    @MainActor
    static func load(from storeURL: URL) throws -> LegacyStoreMigrationData {
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
        let conversations = try context.fetch(FetchDescriptor<Conversation>())
        let notes = try context.fetch(FetchDescriptor<Note>())
        let parties = try context.fetch(FetchDescriptor<Party>())

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
