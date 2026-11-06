
import CoreData
import SwiftData
import Foundation

import Domain

@Model
final class LegacyStoreMigrationRecord {
    #Unique<LegacyStoreMigrationRecord>([\.id])

    var id: String
    var completedDate: Date

    init(
        id: String,
        completedDate: Date
    ) {
        self.id = id
        self.completedDate = completedDate
    }
}

struct LegacyStoreMigrationReport: Sendable {
    let status: Status
    let conversationCount: Int
    let noteCount: Int
    let partyCount: Int
    let issues: [String]
}

extension LegacyStoreMigrationReport {

    enum Status: Equatable, Sendable {
        case alreadyMigrated
        case completed
        case partial
    }

}

@MainActor
struct LegacyStoreMigrator {
    private static let migrationID: String = "v1-v2-to-record-v1"
    private static let v1MigrationID: String = "v1-v2-to-record-v1:v1"
    private static let v2MigrationID: String = "v1-v2-to-record-v1:v2"

    private let dependency: Dependency

    init(dependency: Dependency = .live) {
        self.dependency = dependency
    }
}

extension LegacyStoreMigrator {

    struct Dependency {
        let legacySwiftDataStoreURL: URL
        let legacyCoreDataStoreURL: URL
        let legacyRecordDirectoryURL: URL
        let currentRecordDirectoryURL: URL
        let legacyCoreDataModelURL: URL?
        let temporaryDirectoryURL: URL
        let fileManager: FileManager
        let now: @Sendable () -> Date
    }

}

extension LegacyStoreMigrator.Dependency {

    static var live: Self {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let legacyConfiguration = ModelConfiguration(
            schema: LegacyV2Store.schema,
            cloudKitDatabase: .none
        )

        return .init(
            legacySwiftDataStoreURL: legacyConfiguration.url,
            legacyCoreDataStoreURL: NSPersistentContainer.defaultDirectoryURL()
                .appendingPathComponent(LegacyV1Store.modelName)
                .appendingPathExtension("sqlite"),
            legacyRecordDirectoryURL: documentsURL.appendingPathComponent(
                "Records",
                isDirectory: true
            ),
            currentRecordDirectoryURL: documentsURL.appendingPathComponent(
                "Record",
                isDirectory: true
            ),
            legacyCoreDataModelURL: LegacyV1Store.bundledModelURL,
            temporaryDirectoryURL: fileManager.temporaryDirectory,
            fileManager: fileManager,
            now: { .init() }
        )
    }

}

extension LegacyStoreMigrator {

    func migrate(into modelContainer: ModelContainer) -> LegacyStoreMigrationReport {
        let context = modelContainer.mainContext
        let migrationRecords = migrationRecords(in: context)
        let completedMigrationIDs = Set(migrationRecords.map({ $0.id }))
        let pendingFileRetries = pendingFileRetries(in: migrationRecords)
        let availableMigrationIDs = availableMigrationIDs()
        if isCompleted(
            completedMigrationIDs: completedMigrationIDs,
            availableMigrationIDs: availableMigrationIDs
        ), pendingFileRetries.isEmpty {
            return .init(
                status: .alreadyMigrated,
                conversationCount: 0,
                noteCount: 0,
                partyCount: 0,
                issues: []
            )
        }

        var issues: [String] = []
        let sources = loadSources(
            currentSchema: modelContainer.schema,
            completedMigrationIDs: completedMigrationIDs,
            issues: &issues
        )
        var createdFileURLs: [URL] = []
        let result: InsertionResult
        do {
            result = try insert(
                sources,
                into: context,
                issues: &issues,
                createdFileURLs: &createdFileURLs
            )
            try retryRecordFiles(
                pendingFileRetries,
                currentSchema: modelContainer.schema,
                into: context,
                issues: &issues,
                createdFileURLs: &createdFileURLs
            )
            var completedIDs = result.completedMigrationIDs
            if availableMigrationIDs.isEmpty, issues.isEmpty {
                completedIDs.append(Self.migrationID)
            }
            for id in completedIDs where !completedMigrationIDs.contains(id) {
                context.insert(
                    LegacyStoreMigrationRecord(
                        id: id,
                        completedDate: dependency.now()
                    )
                )
            }
            for retry in result.fileRetries where !completedMigrationIDs.contains(retry.id) {
                context.insert(
                    LegacyStoreMigrationRecord(
                        id: retry.id,
                        completedDate: dependency.now()
                    )
                )
            }
            try context.save()
        } catch {
            context.rollback()
            removeCreatedFiles(createdFileURLs)
            issues.append("Record 저장 실패: \(error)")
            return .init(
                status: .partial,
                conversationCount: 0,
                noteCount: 0,
                partyCount: 0,
                issues: issues
            )
        }

        return .init(
            status: issues.isEmpty ? .completed : .partial,
            conversationCount: result.counts.conversations,
            noteCount: result.counts.notes,
            partyCount: result.counts.parties,
            issues: issues
        )
    }

}

private extension LegacyStoreMigrator {

    struct MigrationSource {
        let id: String
        let data: LegacyStoreMigrationData
    }

    struct MigrationCounts {
        var conversations: Int = 0
        var notes: Int = 0
        var parties: Int = 0
    }

    struct InsertionResult {
        var counts: MigrationCounts = .init()
        var completedMigrationIDs: [String] = []
        var fileRetries: [FileRetryKey] = []
    }

    struct FileRetryKey {
        let sourceID: String
        let conversationID: UUID

        var id: String {
            "\(sourceID):file:\(conversationID.uuidString)"
        }
    }

    struct PendingFileRetry {
        let key: FileRetryKey
        let record: LegacyStoreMigrationRecord
    }

    enum SourceStoreError: Error {
        case unsupportedSwiftDataStore(Error, Error)
        case legacyModelNotFound
        case sourceUnavailable(String)
    }

    func migrationRecords(in context: ModelContext) -> [LegacyStoreMigrationRecord] {
        (try? context.fetch(
            FetchDescriptor<LegacyStoreMigrationRecord>()
        )) ?? []
    }

    func pendingFileRetries(
        in records: [LegacyStoreMigrationRecord]
    ) -> [PendingFileRetry] {
        records.compactMap({ record in
            for sourceID in [Self.v1MigrationID, Self.v2MigrationID] {
                let prefix = "\(sourceID):file:"
                guard record.id.hasPrefix(prefix) else {
                    continue
                }
                guard let conversationID = UUID(
                    uuidString: String(record.id.dropFirst(prefix.count))
                ) else {
                    return nil
                }
                return .init(
                    key: .init(
                        sourceID: sourceID,
                        conversationID: conversationID
                    ),
                    record: record
                )
            }
            return nil
        })
    }

    func availableMigrationIDs() -> Set<String> {
        var ids: Set<String> = []
        if fileExists(at: dependency.legacySwiftDataStoreURL) {
            ids.insert(Self.v2MigrationID)
        }
        if fileExists(at: dependency.legacyCoreDataStoreURL) {
            ids.insert(Self.v1MigrationID)
        }
        return ids
    }

    func isCompleted(
        completedMigrationIDs: Set<String>,
        availableMigrationIDs: Set<String>
    ) -> Bool {
        if completedMigrationIDs.contains(Self.migrationID) {
            return true
        }
        return !availableMigrationIDs.isEmpty
            && availableMigrationIDs.isSubset(of: completedMigrationIDs)
    }

    func loadSources(
        currentSchema: Schema,
        completedMigrationIDs: Set<String>,
        issues: inout [String]
    ) -> [MigrationSource] {
        var sources: [MigrationSource] = []
        if
            fileExists(at: dependency.legacySwiftDataStoreURL),
            !completedMigrationIDs.contains(Self.v2MigrationID)
        {
            do {
                sources.append(try loadSource(
                    id: Self.v2MigrationID,
                    currentSchema: currentSchema
                ))
            } catch {
                issues.append("v2 저장소 읽기 실패: \(error)")
            }
        }
        if
            fileExists(at: dependency.legacyCoreDataStoreURL),
            !completedMigrationIDs.contains(Self.v1MigrationID)
        {
            do {
                sources.append(try loadSource(
                    id: Self.v1MigrationID,
                    currentSchema: currentSchema
                ))
            } catch {
                issues.append("v1 저장소 읽기 실패: \(error)")
            }
        }
        return sources
    }

    func loadSource(
        id: String,
        currentSchema: Schema
    ) throws -> MigrationSource {
        switch id {
            case Self.v2MigrationID:
                guard fileExists(at: dependency.legacySwiftDataStoreURL) else {
                    throw SourceStoreError.sourceUnavailable(id)
                }
                return .init(
                    id: id,
                    data: try loadSwiftDataSource(currentSchema: currentSchema)
                )

            case Self.v1MigrationID:
                guard fileExists(at: dependency.legacyCoreDataStoreURL) else {
                    throw SourceStoreError.sourceUnavailable(id)
                }
                guard let modelURL = dependency.legacyCoreDataModelURL else {
                    throw SourceStoreError.legacyModelNotFound
                }
                let source = try withCopiedStore(
                    at: dependency.legacyCoreDataStoreURL,
                    load: { copiedStoreURL in
                        try LegacyV1Store.load(
                            from: copiedStoreURL,
                            modelURL: modelURL,
                            recordDirectory: dependency.legacyRecordDirectoryURL
                        )
                    }
                )
                return .init(
                    id: id,
                    data: source
                )

            default:
                throw SourceStoreError.sourceUnavailable(id)
        }
    }

    func loadSwiftDataSource(currentSchema: Schema) throws -> LegacyStoreMigrationData {
        do {
            return try withCopiedStore(
                at: dependency.legacySwiftDataStoreURL,
                load: LegacyV2Store.load(from:)
            )
        } catch {
            let legacyError = error
            do {
                return try withCopiedStore(
                    at: dependency.legacySwiftDataStoreURL,
                    load: { copiedStoreURL in
                        try RecordStoreSource.load(
                            from: copiedStoreURL,
                            schema: currentSchema
                        )
                    }
                )
            } catch {
                throw SourceStoreError.unsupportedSwiftDataStore(
                    legacyError,
                    error
                )
            }
        }
    }

    func withCopiedStore<Result>(
        at storeURL: URL,
        load: (URL) throws -> Result
    ) throws -> Result {
        let directoryURL = dependency.temporaryDirectoryURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try dependency.fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer {
            try? dependency.fileManager.removeItem(at: directoryURL)
        }

        let copiedStoreURL = directoryURL.appendingPathComponent(
            storeURL.lastPathComponent,
            isDirectory: false
        )
        for suffix in ["", "-wal", "-shm"] {
            let sourceURL = storeURL
                .deletingLastPathComponent()
                .appendingPathComponent(storeURL.lastPathComponent + suffix)
            guard fileExists(at: sourceURL) else {
                continue
            }
            try dependency.fileManager.copyItem(
                at: sourceURL,
                to: directoryURL.appendingPathComponent(
                    storeURL.lastPathComponent + suffix,
                    isDirectory: false
                )
            )
        }
        return try load(copiedStoreURL)
    }

    func insert(
        _ sources: [MigrationSource],
        into context: ModelContext,
        issues: inout [String],
        createdFileURLs: inout [URL]
    ) throws -> InsertionResult {
        let existingConversations = try context.fetch(
            FetchDescriptor<Domain.Conversation.Record>()
        )
        let existingNotes = try context.fetch(
            FetchDescriptor<Domain.Note.Record>()
        )
        let existingParties = try context.fetch(
            FetchDescriptor<Domain.Party.Record>()
        )
        var conversationsByID = Dictionary(
            uniqueKeysWithValues: existingConversations.map({ ($0.id, $0) })
        )
        var noteIDs = Set(existingNotes.map({ $0.id }))
        var partyIDs = Set(existingParties.map({ $0.id }))
        var claimedFileNames: [String: UUID] = [:]
        for conversation in existingConversations where !conversation.recordFileName.isEmpty {
            claimedFileNames[conversation.recordFileName] = conversation.id
        }
        var result = InsertionResult()

        for source in sources {
            let data = source.data
            var failedFileIDs: Set<UUID> = []
            let sourceParties: [LegacyStoreMigrationData.Party]
            switch data.recordSource {
                case .currentDirectory:
                    sourceParties = data.parties

                case .legacyDirectory:
                    sourceParties = data.conversations
                        .filter({ conversationsByID[$0.id] == nil })
                        .flatMap({ $0.parties })
            }
            for party in sourceParties where !partyIDs.contains(party.id) {
                context.insert(
                    Domain.Party.Record(
                        .init(
                            id: party.id,
                            name: party.name,
                            isAvailable: true
                        )
                    )
                )
                partyIDs.insert(party.id)
                result.counts.parties += 1
            }
            for note in data.notes where !noteIDs.contains(note.id) {
                context.insert(
                    Domain.Note.Record(
                        .init(
                            id: note.id,
                            createdDate: note.createdDate,
                            original: note.original,
                            translation: note.translation,
                            category: note.category == .sentence
                                ? .sentence
                                : .vocabulary
                        )
                    )
                )
                noteIDs.insert(note.id)
                result.counts.notes += 1
            }
            for conversation in data.conversations {
                let existingRecord = conversationsByID[conversation.id]
                let recordFileName = migratedRecordFileName(
                    of: conversation,
                    source: data.recordSource,
                    existingRecord: existingRecord,
                    claimedFileNames: &claimedFileNames,
                    issues: &issues,
                    createdFileURLs: &createdFileURLs,
                    failedFileIDs: &failedFileIDs
                )
                guard existingRecord == nil else {
                    continue
                }
                let domainConversation = Domain.Conversation(
                    id: conversation.id,
                    createdDate: conversation.createdDate,
                    recordFileName: recordFileName,
                    pins: conversation.pins,
                    title: conversation.title,
                    topic: conversation.topic,
                    noteIds: conversation.noteIds,
                    parties: conversation.parties.map({ party in
                        .init(
                            id: party.id,
                            name: party.name,
                            isAvailable: true
                        )
                    })
                )
                let record = Domain.Conversation.Record(domainConversation)
                context.insert(record)
                conversationsByID[conversation.id] = record
                result.counts.conversations += 1
            }
            result.completedMigrationIDs.append(source.id)
            result.fileRetries.append(contentsOf: failedFileIDs.map({ id in
                .init(
                    sourceID: source.id,
                    conversationID: id
                )
            }))
        }
        return result
    }

    func retryRecordFiles(
        _ retries: [PendingFileRetry],
        currentSchema: Schema,
        into context: ModelContext,
        issues: inout [String],
        createdFileURLs: inout [URL]
    ) throws {
        guard !retries.isEmpty else {
            return
        }
        let conversations = try context.fetch(
            FetchDescriptor<Domain.Conversation.Record>()
        )
        let conversationsByID = Dictionary(
            uniqueKeysWithValues: conversations.map({ ($0.id, $0) })
        )
        var claimedFileNames: [String: UUID] = [:]
        for conversation in conversations where !conversation.recordFileName.isEmpty {
            claimedFileNames[conversation.recordFileName] = conversation.id
        }
        let retriesBySource = Dictionary(
            grouping: retries,
            by: { $0.key.sourceID }
        )

        for (sourceID, sourceRetries) in retriesBySource {
            let remainingRetries = sourceRetries.filter({ retry in
                guard conversationsByID[retry.key.conversationID] != nil else {
                    context.delete(retry.record)
                    return false
                }
                return true
            })
            guard !remainingRetries.isEmpty else {
                continue
            }

            let source: MigrationSource
            do {
                source = try loadSource(
                    id: sourceID,
                    currentSchema: currentSchema
                )
            } catch {
                issues.append("녹음 파일 복구 원본 읽기 실패(\(sourceID)): \(error)")
                continue
            }
            let sourceConversationsByID = Dictionary(
                source.data.conversations.map({ ($0.id, $0) }),
                uniquingKeysWith: { first, _ in first }
            )
            for retry in remainingRetries {
                let conversationID = retry.key.conversationID
                guard
                    let existingRecord = conversationsByID[conversationID],
                    let sourceConversation = sourceConversationsByID[conversationID]
                else {
                    context.delete(retry.record)
                    issues.append(
                        "녹음 파일 복구 대상 없음(\(conversationID.uuidString))"
                    )
                    continue
                }
                var failedFileIDs: Set<UUID> = []
                _ = migratedRecordFileName(
                    of: sourceConversation,
                    source: source.data.recordSource,
                    existingRecord: existingRecord,
                    claimedFileNames: &claimedFileNames,
                    issues: &issues,
                    createdFileURLs: &createdFileURLs,
                    failedFileIDs: &failedFileIDs
                )
                if !failedFileIDs.contains(conversationID) {
                    context.delete(retry.record)
                }
            }
        }
    }

}

private extension LegacyStoreMigrator {

    func migratedRecordFileName(
        of conversation: LegacyStoreMigrationData.Conversation,
        source: LegacyStoreMigrationData.RecordSource,
        existingRecord: Domain.Conversation.Record?,
        claimedFileNames: inout [String: UUID],
        issues: inout [String],
        createdFileURLs: inout [URL],
        failedFileIDs: inout Set<UUID>
    ) -> String {
        guard case .legacyDirectory(let sourceDirectoryURL) = source else {
            if !conversation.recordFileName.isEmpty {
                claimedFileNames[conversation.recordFileName] = conversation.id
            }
            return conversation.recordFileName
        }
        guard isValidFileName(conversation.recordFileName) else {
            return ""
        }

        let sourceFileURL = sourceDirectoryURL.appendingPathComponent(
            conversation.recordFileName,
            isDirectory: false
        )
        let originalTargetFileURL = dependency.currentRecordDirectoryURL.appendingPathComponent(
            conversation.recordFileName,
            isDirectory: false
        )
        let sourceFileExists = fileExists(at: sourceFileURL)
        let originalTargetFileNeedsUniqueName = sourceFileExists
            && fileExists(at: originalTargetFileURL)
        let targetFileName: String
        if let existingRecord, isValidFileName(existingRecord.recordFileName) {
            targetFileName = existingRecord.recordFileName
        } else if
            claimedFileNames[conversation.recordFileName] != nil
                || originalTargetFileNeedsUniqueName
        {
            targetFileName = uniqueFileName(
                for: conversation.recordFileName,
                conversationID: conversation.id,
                claimedFileNames: claimedFileNames
            )
        } else {
            targetFileName = conversation.recordFileName
        }
        claimedFileNames[targetFileName] = conversation.id

        let targetFileURL = dependency.currentRecordDirectoryURL.appendingPathComponent(
            targetFileName,
            isDirectory: false
        )
        guard !fileExists(at: targetFileURL) else {
            return targetFileName
        }

        let copySourceURL: URL
        if sourceFileExists {
            copySourceURL = sourceFileURL
        } else {
            let sharedFileURL = dependency.currentRecordDirectoryURL.appendingPathComponent(
                conversation.recordFileName,
                isDirectory: false
            )
            guard fileExists(at: sharedFileURL) else {
                return targetFileName
            }
            copySourceURL = sharedFileURL
        }

        do {
            try dependency.fileManager.createDirectory(
                at: dependency.currentRecordDirectoryURL,
                withIntermediateDirectories: true
            )
            try dependency.fileManager.copyItem(
                at: copySourceURL,
                to: targetFileURL
            )
            createdFileURLs.append(targetFileURL)
        } catch {
            failedFileIDs.insert(conversation.id)
            issues.append(
                "녹음 파일 복사 실패(\(conversation.id.uuidString)): \(error)"
            )
        }
        return targetFileName
    }

    func uniqueFileName(
        for fileName: String,
        conversationID: UUID,
        claimedFileNames: [String: UUID]
    ) -> String {
        let sourceURL = URL(fileURLWithPath: fileName)
        let stem = sourceURL.deletingPathExtension().lastPathComponent
        let fileExtension = sourceURL.pathExtension
        let suffixes = [
            String(conversationID.uuidString.prefix(8)),
            conversationID.uuidString
        ]
        for suffix in suffixes {
            let candidate = fileExtension.isEmpty
                ? "\(stem)_\(suffix)"
                : "\(stem)_\(suffix).\(fileExtension)"
            let candidateURL = dependency.currentRecordDirectoryURL.appendingPathComponent(
                candidate,
                isDirectory: false
            )
            if claimedFileNames[candidate] == nil, !fileExists(at: candidateURL) {
                return candidate
            }
        }
        return fileExtension.isEmpty
            ? conversationID.uuidString
            : "\(conversationID.uuidString).\(fileExtension)"
    }

    func isValidFileName(_ fileName: String) -> Bool {
        !fileName.isEmpty
            && !fileName.contains("/")
            && fileName != "."
            && fileName != ".."
    }

    func fileExists(at url: URL) -> Bool {
        dependency.fileManager.fileExists(
            atPath: url.path(percentEncoded: false)
        )
    }

    func removeCreatedFiles(_ fileURLs: [URL]) {
        for fileURL in fileURLs {
            try? dependency.fileManager.removeItem(at: fileURL)
        }
    }

}
