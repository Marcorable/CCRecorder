
import CoreData
import Foundation
import SwiftData

struct LegacyStoreMigrator {
    enum MigrationError: Error {
        case modelNotFound
        case incompatibleStore
        case storeLoadFailed(Error)
        case recordMoveFailed(Error)
        case saveFailed(Error)
    }

    enum Outcome: Equatable {
        case alreadyMigrated
        case noLegacyStore
        case migrated(conversations: Int, notes: Int)
    }

    static let modelName: String = "CasualConversation"

    private let dependency: Dependency

    init(dependency: Dependency = .live) {
        self.dependency = dependency
    }
}

extension LegacyStoreMigrator {

    struct Dependency {
        let storeURL: URL
        let modelURL: URL?
        let legacyRecordDirectories: [URL]
        let fileStore: RecordFileStore
        let userDefaults: UserDefaults
        let fileManager: FileManager
    }

}

extension LegacyStoreMigrator.Dependency {

    static var live: Self {
        let fileManager = FileManager.default
        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        return .init(
            storeURL: NSPersistentContainer.defaultDirectoryURL()
                .appendingPathComponent(LegacyStoreMigrator.modelName)
                .appendingPathExtension("sqlite"),
            modelURL: Bundle.main.url(forResource: LegacyStoreMigrator.modelName, withExtension: "momd"),
            legacyRecordDirectories: [documentURL.appendingPathComponent("Records", isDirectory: true)],
            fileStore: .init(fileManager: fileManager),
            userDefaults: .standard,
            fileManager: fileManager
        )
    }

}

extension LegacyStoreMigrator {

    @MainActor
    func migrateIfNeeded(into modelContext: ModelContext) throws -> Outcome {
        guard !dependency.userDefaults.bool(forKey: .Key.isLegacyStoreMigrated) else {
            return .alreadyMigrated
        }
        guard dependency.fileManager.fileExists(atPath: dependency.storeURL.path(percentEncoded: false)) else {
            dependency.userDefaults.set(true, forKey: .Key.isLegacyStoreMigrated)
            return .noLegacyStore
        }

        let legacyData = try loadLegacyData()
        let outcome = try insert(legacyData, into: modelContext)
        dependency.userDefaults.set(true, forKey: .Key.isLegacyStoreMigrated)
        return outcome
    }

}

private extension LegacyStoreMigrator {

    struct LegacyConversation {
        let id: UUID
        let title: String?
        let topic: String?
        let members: [String]
        let pins: [TimeInterval]
        let recordedDate: Date?
        let recordFilePath: URL?
    }

    struct LegacyNote {
        let id: UUID
        let original: String?
        let translation: String?
        let category: String?
        let references: [UUID]
        let createdDate: Date?
    }

    struct LegacyData {
        let conversations: [LegacyConversation]
        let notes: [LegacyNote]
    }

    enum RecordChange {
        case moved(source: URL, destination: URL)
        case copied(URL)
    }

}

private extension LegacyStoreMigrator {

    @MainActor
    func loadLegacyData() throws -> LegacyData {
        guard
            let modelURL = dependency.modelURL,
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            throw MigrationError.modelNotFound
        }

        let metadata: [String: Any]
        do {
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                type: .sqlite,
                at: dependency.storeURL
            )
        } catch {
            throw MigrationError.storeLoadFailed(error)
        }
        guard model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else {
            throw MigrationError.incompatibleStore
        }

        let copyDirectoryURL = dependency.fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? dependency.fileManager.removeItem(at: copyDirectoryURL) }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            let copiedStoreURL = try copyStore(to: copyDirectoryURL)
            try coordinator.addPersistentStore(
                type: .sqlite,
                at: copiedStoreURL
            )
        } catch {
            throw MigrationError.storeLoadFailed(error)
        }

        let context = NSManagedObjectContext(.mainQueue)
        context.persistentStoreCoordinator = coordinator

        do {
            return LegacyData(
                conversations: try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "ConversationEntity"))
                    .map(Self.conversation(from:)),
                notes: try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "NoteEntity"))
                    .map(Self.note(from:))
            )
        } catch {
            throw MigrationError.storeLoadFailed(error)
        }
    }

    func copyStore(to directoryURL: URL) throws -> URL {
        try dependency.fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let storeFileName = dependency.storeURL.lastPathComponent
        for suffix in ["", "-wal", "-shm"] {
            let sourceURL = dependency.storeURL
                .deletingLastPathComponent()
                .appendingPathComponent(storeFileName + suffix)
            guard dependency.fileManager.fileExists(atPath: sourceURL.path(percentEncoded: false)) else {
                continue
            }
            try dependency.fileManager.copyItem(
                at: sourceURL,
                to: directoryURL.appendingPathComponent(storeFileName + suffix)
            )
        }
        return directoryURL.appendingPathComponent(storeFileName)
    }

    static func conversation(from object: NSManagedObject) -> LegacyConversation {
        LegacyConversation(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            title: object.value(forKey: "title") as? String,
            topic: object.value(forKey: "topic") as? String,
            members: object.value(forKey: "members") as? [String] ?? [],
            pins: object.value(forKey: "pins") as? [TimeInterval] ?? [],
            recordedDate: object.value(forKey: "recordedDate") as? Date,
            recordFilePath: object.value(forKey: "recordFilePath") as? URL
        )
    }

    static func note(from object: NSManagedObject) -> LegacyNote {
        LegacyNote(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            original: object.value(forKey: "original") as? String,
            translation: object.value(forKey: "translation") as? String,
            category: object.value(forKey: "category") as? String,
            references: object.value(forKey: "references") as? [UUID] ?? [],
            createdDate: object.value(forKey: "createdDate") as? Date
        )
    }

}

private extension LegacyStoreMigrator {

    @MainActor
    func insert(_ legacyData: LegacyData, into modelContext: ModelContext) throws -> Outcome {
        let existingConversations: [Conversation]
        let existingNoteIds: Set<UUID>
        do {
            existingConversations = try modelContext.fetch(FetchDescriptor<Conversation>())
            existingNoteIds = Set(try modelContext.fetch(FetchDescriptor<Note>()).map(\.id))
        } catch {
            throw MigrationError.saveFailed(error)
        }

        var noteIdsByConversation: [UUID: [UUID]] = [:]
        for note in legacyData.notes {
            for conversationId in note.references {
                noteIdsByConversation[conversationId, default: []].append(note.id)
            }
        }

        let existingConversationIds = Set(existingConversations.map(\.id))
        let newConversations = legacyData.conversations.filter { !existingConversationIds.contains($0.id) }
        let newNotes = legacyData.notes.filter { !existingNoteIds.contains($0.id) }

        var claimedFileNames = Set(existingConversations.map(\.recordFileName).filter { !$0.isEmpty })
        var recordChanges: [RecordChange] = []
        do {
            for legacy in newConversations {
                let recordFileName = try migrateRecord(
                    of: legacy,
                    claimedFileNames: &claimedFileNames,
                    recordChanges: &recordChanges
                )
                modelContext.insert(Self.conversation(
                    from: legacy,
                    recordFileName: recordFileName,
                    noteIds: noteIdsByConversation[legacy.id] ?? []
                ))
            }
            for legacy in newNotes {
                modelContext.insert(Self.note(from: legacy))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            restore(recordChanges)
            if let error = error as? MigrationError {
                throw error
            }
            throw MigrationError.saveFailed(error)
        }

        return .migrated(conversations: newConversations.count, notes: newNotes.count)
    }

    func migrateRecord(
        of legacy: LegacyConversation,
        claimedFileNames: inout Set<String>,
        recordChanges: inout [RecordChange]
    ) throws -> String {
        let fileName = legacy.recordFilePath?.lastPathComponent ?? ""
        guard let destination = dependency.fileStore.fileURL(of: fileName) else {
            return ""
        }

        if claimedFileNames.contains(fileName) {
            return try copyRecord(
                at: destination,
                for: legacy,
                claimedFileNames: &claimedFileNames,
                recordChanges: &recordChanges
            )
        }
        claimedFileNames.insert(fileName)

        guard !dependency.fileStore.fileExists(at: destination) else {
            return fileName
        }

        for directoryURL in dependency.legacyRecordDirectories {
            let source = directoryURL.appendingPathComponent(fileName, isDirectory: false)
            guard dependency.fileStore.fileExists(at: source) else {
                continue
            }

            do {
                try dependency.fileStore.prepareDirectory()
                try dependency.fileManager.moveItem(at: source, to: destination)
            } catch {
                throw MigrationError.recordMoveFailed(error)
            }
            recordChanges.append(.moved(source: source, destination: destination))
            return fileName
        }

        return fileName
    }

    func copyRecord(
        at sharedFileURL: URL,
        for legacy: LegacyConversation,
        claimedFileNames: inout Set<String>,
        recordChanges: inout [RecordChange]
    ) throws -> String {
        let sharedFileName = sharedFileURL.lastPathComponent
        guard dependency.fileStore.fileExists(at: sharedFileURL) else {
            return sharedFileName
        }

        let copiedFileName = sharedFileURL.deletingPathExtension().lastPathComponent
            + "_" + legacy.id.uuidString.prefix(8)
            + "." + sharedFileURL.pathExtension
        guard let copiedFileURL = dependency.fileStore.fileURL(of: copiedFileName) else {
            return sharedFileName
        }

        if !dependency.fileStore.fileExists(at: copiedFileURL) {
            do {
                try dependency.fileManager.copyItem(at: sharedFileURL, to: copiedFileURL)
            } catch {
                throw MigrationError.recordMoveFailed(error)
            }
            recordChanges.append(.copied(copiedFileURL))
        }
        claimedFileNames.insert(copiedFileName)
        return copiedFileName
    }

    func restore(_ recordChanges: [RecordChange]) {
        for change in recordChanges.reversed() {
            switch change {
                case .moved(let source, let destination):
                    try? dependency.fileManager.moveItem(at: destination, to: source)

                case .copied(let url):
                    try? dependency.fileManager.removeItem(at: url)
            }
        }
    }

    static func conversation(
        from legacy: LegacyConversation,
        recordFileName: String,
        noteIds: [UUID]
    ) -> Conversation {
        let createdDate = legacy.recordedDate ?? .now
        let title = legacy.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return Conversation(
            id: legacy.id,
            createdDate: createdDate,
            recordFileName: recordFileName,
            pins: legacy.pins,
            title: title.isEmpty ? RecordScreen.defaultTitle(of: createdDate) : title,
            topic: legacy.topic ?? "",
            notes: noteIds,
            parties: legacy.members.map { Party(name: $0) }
        )
    }

    static func note(from legacy: LegacyNote) -> Note {
        Note(
            id: legacy.id,
            createdDate: legacy.createdDate ?? .now,
            original: legacy.original ?? "",
            translation: legacy.translation ?? "",
            category: legacy.category == "sentence" ? .sentence : .vocabulary
        )
    }

}
