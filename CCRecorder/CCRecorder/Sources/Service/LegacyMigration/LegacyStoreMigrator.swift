
import CoreData
import Foundation
import SwiftData

/// [AI] v1(App Store 1.1.0) 의 CoreData 대화·노트와 녹음 파일을 v2 로 옮긴다.
/// 실패하면 v1 원본을 그대로 두고 다음 실행에 다시 시도한다.
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

    struct MovedRecord {
        let source: URL
        let destination: URL
    }

}

private extension LegacyStoreMigrator {

    /// [AI] v1 원본을 건드리지 않도록 임시 디렉토리에 복사본을 만들어 읽는다.
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

    /// [AI] WAL 모드라 `-wal`, `-shm` 파일까지 함께 복사해야 최근 변경이 빠지지 않는다.
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

    /// [AI] 녹음 파일을 먼저 옮기고 저장한다. 저장에 실패하면 옮긴 파일을 되돌린다.
    @MainActor
    func insert(_ legacyData: LegacyData, into modelContext: ModelContext) throws -> Outcome {
        let existingConversationIds: Set<UUID>
        let existingNoteIds: Set<UUID>
        do {
            existingConversationIds = Set(try modelContext.fetch(FetchDescriptor<Conversation>()).map(\.id))
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

        let newConversations = legacyData.conversations.filter { !existingConversationIds.contains($0.id) }
        let newNotes = legacyData.notes.filter { !existingNoteIds.contains($0.id) }

        var movedRecords: [MovedRecord] = []
        do {
            for legacy in newConversations {
                let recordFileName = try moveRecord(of: legacy, movedRecords: &movedRecords)
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
            restore(movedRecords)
            if let error = error as? MigrationError {
                throw error
            }
            throw MigrationError.saveFailed(error)
        }

        return .migrated(conversations: newConversations.count, notes: newNotes.count)
    }

    /// [AI] v1 녹음 디렉토리에서 파일 이름으로 찾아 v2 녹음 디렉토리로 옮기고, 저장할 파일 이름을 돌려준다.
    func moveRecord(of legacy: LegacyConversation, movedRecords: inout [MovedRecord]) throws -> String {
        let fileName = legacy.recordFilePath?.lastPathComponent ?? ""
        guard let destination = dependency.fileStore.fileURL(of: fileName) else {
            return ""
        }
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
            movedRecords.append(.init(source: source, destination: destination))
            return fileName
        }

        return fileName
    }

    func restore(_ movedRecords: [MovedRecord]) {
        for record in movedRecords.reversed() {
            try? dependency.fileManager.moveItem(at: record.destination, to: record.source)
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
