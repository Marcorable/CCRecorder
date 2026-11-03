
import CoreData
import Foundation

enum LegacyV1Store {
    static let modelName: String = "CasualConversation"
}

extension LegacyV1Store {

    static var bundledModelURL: URL? {
        Bundle(for: BundleToken.self).url(
            forResource: modelName,
            withExtension: "momd"
        )
    }

    @MainActor
    static func load(
        from storeURL: URL,
        modelURL: URL,
        recordDirectory: URL
    ) throws -> LegacyStoreMigrationData {
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw StoreError.modelNotFound
        }
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            type: .sqlite,
            at: storeURL
        )
        guard model.isConfiguration(
            withName: nil,
            compatibleWithStoreMetadata: metadata
        ) else {
            throw StoreError.incompatibleStore
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let persistentStore = try coordinator.addPersistentStore(
            type: .sqlite,
            at: storeURL
        )
        defer {
            try? coordinator.remove(persistentStore)
        }
        let context = NSManagedObjectContext(.mainQueue)
        context.persistentStoreCoordinator = coordinator

        let legacyConversations = try context.fetch(
            NSFetchRequest<NSManagedObject>(entityName: "ConversationEntity")
        )
        let legacyNotes = try context.fetch(
            NSFetchRequest<NSManagedObject>(entityName: "NoteEntity")
        )
        let notes = legacyNotes.map(note(from:))
        var noteIdsByConversation: [UUID: [UUID]] = [:]
        for (object, note) in zip(legacyNotes, notes) {
            let references = object.value(forKey: "references") as? [UUID] ?? []
            for conversationID in references {
                noteIdsByConversation[conversationID, default: []].append(note.id)
            }
        }

        let conversations = legacyConversations.map({ object in
            conversation(
                from: object,
                noteIdsByConversation: noteIdsByConversation
            )
        })
        let parties = Dictionary(
            conversations
                .flatMap({ $0.parties })
                .map({ ($0.id, $0) }),
            uniquingKeysWith: { first, _ in first }
        )

        return .init(
            conversations: conversations,
            notes: notes,
            parties: Array(parties.values),
            recordSource: .legacyDirectory(recordDirectory)
        )
    }

}

extension LegacyV1Store {

    enum StoreError: Error {
        case modelNotFound
        case incompatibleStore
    }

}

private extension LegacyV1Store {

    final class BundleToken {}

    static func conversation(
        from object: NSManagedObject,
        noteIdsByConversation: [UUID: [UUID]]
    ) -> LegacyStoreMigrationData.Conversation {
        let id = object.value(forKey: "id") as? UUID
            ?? stableUUID(for: "conversation:\(object.objectID.uriRepresentation().absoluteString)")
        let memberNames = object.value(forKey: "members") as? [String] ?? []
        let parties = memberNames.enumerated().map({ index, name in
            LegacyStoreMigrationData.Party(
                id: stableUUID(for: "party:\(id.uuidString):\(index):\(name)"),
                name: name
            )
        })
        let recordFilePath = object.value(forKey: "recordFilePath") as? URL

        return .init(
            id: id,
            createdDate: object.value(forKey: "recordedDate") as? Date ?? .distantPast,
            recordFileName: recordFilePath?.lastPathComponent ?? "",
            pins: object.value(forKey: "pins") as? [TimeInterval] ?? [],
            title: object.value(forKey: "title") as? String ?? "",
            topic: object.value(forKey: "topic") as? String ?? "",
            noteIds: noteIdsByConversation[id] ?? [],
            parties: parties
        )
    }

    static func note(from object: NSManagedObject) -> LegacyStoreMigrationData.Note {
        let id = object.value(forKey: "id") as? UUID
            ?? stableUUID(for: "note:\(object.objectID.uriRepresentation().absoluteString)")
        let category: LegacyStoreMigrationData.Note.Category = object.value(forKey: "category") as? String == "sentence"
            ? .sentence
            : .vocabulary

        return .init(
            id: id,
            createdDate: object.value(forKey: "createdDate") as? Date ?? .distantPast,
            original: object.value(forKey: "original") as? String ?? "",
            translation: object.value(forKey: "translation") as? String ?? "",
            category: category
        )
    }

    static func stableUUID(for value: String) -> UUID {
        let first = hash(value.utf8, offset: 0xcbf29ce484222325)
        let second = hash(value.utf8, offset: 0x84222325cbf29ce4)
        var bytes = bytes(of: first) + bytes(of: second)
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        return .init(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
    }

    static func hash(
        _ bytes: String.UTF8View,
        offset: UInt64
    ) -> UInt64 {
        bytes.reduce(offset, { hash, byte in
            (hash ^ UInt64(byte)) &* 0x100000001b3
        })
    }

    static func bytes(of value: UInt64) -> [UInt8] {
        (0..<8).map({ index in
            UInt8(truncatingIfNeeded: value >> UInt64((7 - index) * 8))
        })
    }

}
