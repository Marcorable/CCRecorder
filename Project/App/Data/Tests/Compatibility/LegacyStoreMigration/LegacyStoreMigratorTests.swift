
import Testing
import CoreData
import SwiftData
import Foundation

import Domain

@testable import Data

@Suite("v1·v2 Record 저장소 마이그레이션", .serialized)
@MainActor
struct LegacyStoreMigratorTests {
    private let baseURL: URL
    private let v2StoreURL: URL
    private let v1StoreURL: URL
    private let legacyRecordDirectoryURL: URL
    private let currentRecordDirectoryURL: URL
    private let destinationContainer: ModelContainer

    init() throws {
        let baseURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let documentsURL = baseURL.appendingPathComponent(
            "Documents",
            isDirectory: true
        )
        let legacyRecordDirectoryURL = documentsURL.appendingPathComponent(
            "Records",
            isDirectory: true
        )
        let currentRecordDirectoryURL = documentsURL.appendingPathComponent(
            "Record",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: legacyRecordDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: currentRecordDirectoryURL,
            withIntermediateDirectories: true
        )

        self.baseURL = baseURL
        self.v2StoreURL = baseURL.appendingPathComponent("default.store")
        self.v1StoreURL = baseURL.appendingPathComponent("CasualConversation.sqlite")
        self.legacyRecordDirectoryURL = legacyRecordDirectoryURL
        self.currentRecordDirectoryURL = currentRecordDirectoryURL
        self.destinationContainer = try makeTestModelContainer()
    }
}

extension LegacyStoreMigratorTests {

    @Test("배포된 v2 대화·노트·참여자와 녹음 연결을 원본 변경 없이 보존한다")
    func migratesV2StoreWithoutChangingOriginal() throws {
        defer { cleanUp() }

        // given
        let conversationID = UUID()
        let noteID = UUID()
        let partyID = UUID()
        let createdDate = Date(timeIntervalSince1970: 1_700_000_000)
        try makeV2Fixture(
            conversationID: conversationID,
            noteID: noteID,
            partyID: partyID,
            createdDate: createdDate
        )
        let fileURL = currentRecordDirectoryURL.appendingPathComponent("v2.m4a")
        try Data("v2-recording".utf8).write(to: fileURL)
        let originalStore = try storeSnapshot(at: v2StoreURL)

        // when
        let report = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(report.status == .completed)
        #expect(report.issues.isEmpty)
        let context = destinationContainer.mainContext
        let conversation = try #require(
            try context.fetch(FetchDescriptor<Domain.Conversation.Record>()).first
        )
        #expect(conversation.id == conversationID)
        #expect(conversation.createdDate == createdDate)
        #expect(conversation.recordFileName == "v2.m4a")
        #expect(conversation.pins == [1.25, 8.5])
        #expect(conversation.title == "v2 대화")
        #expect(conversation.topic == "마이그레이션")
        #expect(conversation.noteIds == [noteID])
        #expect(conversation.parties.count == 1)
        #expect(conversation.parties.first?.id == partyID)
        #expect(conversation.parties.first?.name == "Marco")

        let note = try #require(
            try context.fetch(FetchDescriptor<Domain.Note.Record>()).first
        )
        #expect(note.id == noteID)
        #expect(note.createdDate == createdDate)
        #expect(note.original == "How are you?")
        #expect(note.translation == "잘 지내?")
        #expect(note.category == .sentence)

        let party = try #require(
            try context.fetch(FetchDescriptor<Domain.Party.Record>()).first
        )
        #expect(party.id == partyID)
        #expect(party.name == "Marco")
        #expect(try Data(contentsOf: fileURL) == Data("v2-recording".utf8))
        #expect(try storeSnapshot(at: v2StoreURL) == originalStore)
    }

    @Test("v2와 v1 원본이 함께 남아 있으면 v2 값을 우선하고 v1 참여자를 중복하지 않는다")
    func v2StoreTakesPrecedenceOverRemainingV1Store() throws {
        defer { cleanUp() }

        // given
        let conversationID = UUID()
        let noteID = UUID()
        let partyID = UUID()
        try makeV2Fixture(
            conversationID: conversationID,
            noteID: noteID,
            partyID: partyID,
            createdDate: .now
        )
        try makeV1Fixture(
            conversations: [
                .init(
                    id: conversationID,
                    title: "이전 v1 대화",
                    members: ["중복 참여자"],
                    pins: [],
                    recordedDate: .now,
                    fileName: "legacy.m4a"
                )
            ],
            notes: [
                .init(
                    id: noteID,
                    original: "legacy",
                    translation: "레거시",
                    category: "vocabulary",
                    references: [conversationID],
                    createdDate: .now
                )
            ]
        )

        // when
        let report = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(report.status == .completed)
        let context = destinationContainer.mainContext
        let conversation = try #require(
            try context.fetch(FetchDescriptor<Domain.Conversation.Record>()).first
        )
        #expect(conversation.title == "v2 대화")
        #expect(conversation.recordFileName == "v2.m4a")
        #expect(conversation.parties.map({ $0.id }) == [partyID])
        let notes = try context.fetch(FetchDescriptor<Domain.Note.Record>())
        #expect(notes.count == 1)
        #expect(notes.first?.original == "How are you?")
        let parties = try context.fetch(FetchDescriptor<Domain.Party.Record>())
        #expect(parties.count == 1)
        #expect(parties.first?.id == partyID)
    }

    @Test("v1 대화·노트와 녹음을 복사하고 공유 녹음은 독립 파일로 연결한다")
    func migratesV1StoreAndCopiesSharedRecording() throws {
        defer { cleanUp() }

        // given
        let firstConversationID = UUID()
        let secondConversationID = UUID()
        let noteID = UUID()
        let createdDate = Date(timeIntervalSince1970: 1_660_000_000)
        try makeV1Fixture(
            conversations: [
                .init(
                    id: firstConversationID,
                    title: "첫 대화",
                    members: ["Marco", "Coda"],
                    pins: [2.5],
                    recordedDate: createdDate,
                    fileName: "shared.m4a"
                ),
                .init(
                    id: secondConversationID,
                    title: "둘째 대화",
                    members: ["Coda"],
                    pins: [],
                    recordedDate: createdDate,
                    fileName: "shared.m4a"
                )
            ],
            notes: [
                .init(
                    id: noteID,
                    original: "legacy",
                    translation: "레거시",
                    category: "vocabulary",
                    references: [firstConversationID],
                    createdDate: createdDate
                )
            ]
        )
        let sourceFileURL = legacyRecordDirectoryURL.appendingPathComponent("shared.m4a")
        let recording = Data("v1-recording".utf8)
        try recording.write(to: sourceFileURL)
        let originalStore = try storeSnapshot(at: v1StoreURL)

        // when
        let report = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(report.status == .completed)
        let context = destinationContainer.mainContext
        let conversations = try context.fetch(
            FetchDescriptor<Domain.Conversation.Record>()
        )
        #expect(conversations.count == 2)
        let first = try #require(
            conversations.first(where: { $0.id == firstConversationID })
        )
        #expect(first.createdDate == createdDate)
        #expect(first.pins == [2.5])
        #expect(first.noteIds == [noteID])
        #expect(Set(first.parties.map({ $0.name })) == ["Marco", "Coda"])

        let fileNames = Set(conversations.map({ $0.recordFileName }))
        #expect(fileNames.count == 2)
        let migratedFileURLs = fileNames.map({ fileName in
            currentRecordDirectoryURL.appendingPathComponent(fileName)
        })
        #expect(migratedFileURLs.allSatisfy({ FileManager.default.fileExists(atPath: $0.path) }))
        #expect(try migratedFileURLs.allSatisfy({ try Data(contentsOf: $0) == recording }))
        #expect(FileManager.default.fileExists(atPath: sourceFileURL.path))
        #expect(try Data(contentsOf: sourceFileURL) == recording)
        #expect(try storeSnapshot(at: v1StoreURL) == originalStore)

        // when
        try FileManager.default.removeItem(at: migratedFileURLs[0])

        // then
        #expect(FileManager.default.fileExists(atPath: migratedFileURLs[1].path))
    }

    @Test("빈 저장소는 완료 처리하고 재실행해도 데이터를 만들지 않는다")
    func emptyStoreCompletesOnlyOnce() throws {
        defer { cleanUp() }

        // when
        let firstReport = makeSUT().migrate(into: destinationContainer)
        let secondReport = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(firstReport.status == .completed)
        #expect(secondReport.status == .alreadyMigrated)
        let context = destinationContainer.mainContext
        #expect(try context.fetchCount(FetchDescriptor<Domain.Conversation.Record>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Domain.Note.Record>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Domain.Party.Record>()) == 0)
    }

    @Test("완료 표시를 잃고 재실행해도 ID가 같은 데이터를 중복하지 않는다")
    func rerunWithoutMarkerDoesNotDuplicateData() throws {
        defer { cleanUp() }

        // given
        try makeV2Fixture(
            conversationID: UUID(),
            noteID: UUID(),
            partyID: UUID(),
            createdDate: .now
        )
        _ = makeSUT().migrate(into: destinationContainer)
        let context = destinationContainer.mainContext
        for marker in try context.fetch(FetchDescriptor<LegacyStoreMigrationRecord>()) {
            context.delete(marker)
        }
        try context.save()

        // when
        let report = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(report.status == .completed)
        #expect(try context.fetchCount(FetchDescriptor<Domain.Conversation.Record>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Domain.Note.Record>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Domain.Party.Record>()) == 1)
    }

    @Test("v1 필드와 녹음 파일이 누락되어도 가능한 데이터는 보존한다")
    func incompleteV1DataPreservesAvailableValues() throws {
        defer { cleanUp() }

        // given
        let conversationID = UUID()
        let noteID = UUID()
        try makeV1Fixture(
            conversations: [
                .init(
                    id: conversationID,
                    title: nil,
                    members: ["Marco"],
                    pins: [],
                    recordedDate: nil,
                    fileName: "missing.m4a"
                )
            ],
            notes: [
                .init(
                    id: noteID,
                    original: "known",
                    translation: nil,
                    category: nil,
                    references: [conversationID],
                    createdDate: nil
                )
            ]
        )

        // when
        let report = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(report.status == .completed)
        let context = destinationContainer.mainContext
        let conversation = try #require(
            try context.fetch(FetchDescriptor<Domain.Conversation.Record>()).first
        )
        #expect(conversation.id == conversationID)
        #expect(conversation.title.isEmpty)
        #expect(conversation.recordFileName == "missing.m4a")
        #expect(conversation.noteIds == [noteID])
        #expect(conversation.parties.map({ $0.name }) == ["Marco"])
        let note = try #require(
            try context.fetch(FetchDescriptor<Domain.Note.Record>()).first
        )
        #expect(note.id == noteID)
        #expect(note.original == "known")
        #expect(note.translation.isEmpty)
        #expect(note.category == .vocabulary)
    }

    @Test("손상된 원본은 유지하고 앱이 사용할 빈 Record 저장소를 남긴다")
    func corruptedSourceKeepsOriginalAndReturnsPartial() throws {
        defer { cleanUp() }

        // given
        let original = Data("not-a-store".utf8)
        try original.write(to: v1StoreURL)

        // when
        let report = makeSUT().migrate(into: destinationContainer)

        // then
        #expect(report.status == .partial)
        #expect(!report.issues.isEmpty)
        #expect(try Data(contentsOf: v1StoreURL) == original)
        let context = destinationContainer.mainContext
        #expect(try context.fetchCount(FetchDescriptor<Domain.Conversation.Record>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<LegacyStoreMigrationRecord>()) == 0)
    }

}

private extension LegacyStoreMigratorTests {

    struct V1ConversationFixture {
        let id: UUID
        let title: String?
        let members: [String]
        let pins: [TimeInterval]
        let recordedDate: Date?
        let fileName: String
    }

    struct V1NoteFixture {
        let id: UUID
        let original: String?
        let translation: String?
        let category: String?
        let references: [UUID]
        let createdDate: Date?
    }

    func makeSUT() -> LegacyStoreMigrator {
        .init(
            dependency: .init(
                legacySwiftDataStoreURL: v2StoreURL,
                legacyCoreDataStoreURL: v1StoreURL,
                legacyRecordDirectoryURL: legacyRecordDirectoryURL,
                currentRecordDirectoryURL: currentRecordDirectoryURL,
                legacyCoreDataModelURL: LegacyV1Store.bundledModelURL,
                temporaryDirectoryURL: baseURL.appendingPathComponent(
                    "Temporary",
                    isDirectory: true
                ),
                fileManager: .default,
                now: { Date(timeIntervalSince1970: 1_800_000_000) }
            )
        )
    }

    func makeV2Fixture(
        conversationID: UUID,
        noteID: UUID,
        partyID: UUID,
        createdDate: Date
    ) throws {
        let schema = Schema(
            [
                Conversation.self,
                Note.self,
                Party.self
            ]
        )
        let container = try ModelContainer(
            for: schema,
            configurations: .init(
                schema: schema,
                url: v2StoreURL,
                cloudKitDatabase: .none
            )
        )
        let party = Party(
            id: partyID,
            name: "Marco"
        )
        container.mainContext.insert(party)
        container.mainContext.insert(
            Note(
                id: noteID,
                createdDate: createdDate,
                original: "How are you?",
                translation: "잘 지내?",
                category: .sentence
            )
        )
        container.mainContext.insert(
            Conversation(
                id: conversationID,
                createdDate: createdDate,
                recordFileName: "v2.m4a",
                pins: [1.25, 8.5],
                title: "v2 대화",
                topic: "마이그레이션",
                notes: [noteID],
                parties: [party]
            )
        )
        try container.mainContext.save()
    }

    func makeV1Fixture(
        conversations: [V1ConversationFixture],
        notes: [V1NoteFixture]
    ) throws {
        let modelURL = try #require(LegacyV1Store.bundledModelURL)
        let model = try #require(NSManagedObjectModel(contentsOf: modelURL))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(
            type: .sqlite,
            at: v1StoreURL
        )
        let context = NSManagedObjectContext(.mainQueue)
        context.persistentStoreCoordinator = coordinator

        for fixture in conversations {
            let object = NSEntityDescription.insertNewObject(
                forEntityName: "ConversationEntity",
                into: context
            )
            object.setValue(fixture.id, forKey: "id")
            object.setValue(fixture.title, forKey: "title")
            object.setValue("주제", forKey: "topic")
            object.setValue(fixture.members, forKey: "members")
            object.setValue(fixture.pins, forKey: "pins")
            object.setValue(fixture.recordedDate, forKey: "recordedDate")
            object.setValue(
                URL(fileURLWithPath: "/old/Documents/Records/\(fixture.fileName)"),
                forKey: "recordFilePath"
            )
        }
        for fixture in notes {
            let object = NSEntityDescription.insertNewObject(
                forEntityName: "NoteEntity",
                into: context
            )
            object.setValue(fixture.id, forKey: "id")
            object.setValue(fixture.original, forKey: "original")
            object.setValue(fixture.translation, forKey: "translation")
            object.setValue(fixture.category, forKey: "category")
            object.setValue(fixture.references, forKey: "references")
            object.setValue(fixture.createdDate, forKey: "createdDate")
        }
        try context.save()
        try coordinator.remove(store)
    }

    func storeSnapshot(at storeURL: URL) throws -> [String: Data] {
        var snapshot: [String: Data] = [:]
        for suffix in ["", "-wal", "-shm"] {
            let url = storeURL
                .deletingLastPathComponent()
                .appendingPathComponent(storeURL.lastPathComponent + suffix)
            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }
            snapshot[suffix] = try Data(contentsOf: url)
        }
        return snapshot
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: baseURL)
    }

}

@Model
private final class Conversation {
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
private final class Note {
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
private final class Party {
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
