
import CoreData
import Foundation
import SwiftData
import Testing

@testable import CCRecorder

@Suite("v1 데이터 마이그레이션", .serialized)
@MainActor
struct LegacyStoreMigratorTests {
    private let baseURL: URL
    private let storeURL: URL
    private let legacyRecordDirectory: URL
    private let fileStore: RecordFileStore
    private let userDefaults: UserDefaults
    private let modelContext: ModelContext

    init() throws {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let legacyRecordDirectory = baseURL.appendingPathComponent("Records", isDirectory: true)
        try FileManager.default.createDirectory(at: legacyRecordDirectory, withIntermediateDirectories: true)

        let container = try ModelContainer(
            for: Conversation.self, Note.self, Party.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let suiteName = "LegacyStoreMigratorTests.\(UUID().uuidString)"

        self.baseURL = baseURL
        self.storeURL = baseURL.appendingPathComponent("CasualConversation.sqlite")
        self.legacyRecordDirectory = legacyRecordDirectory
        self.fileStore = RecordFileStore(baseURL: baseURL)
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
        self.modelContext = .init(container)
    }
}

extension LegacyStoreMigratorTests {

    @Test("v1 대화와 노트를 v2 모델로 옮긴다")
    func migratesConversationsAndNotes() throws {
        defer { cleanUp() }

        // given
        let conversationId = UUID()
        let noteId = UUID()
        let recordedDate = Date(timeIntervalSince1970: 1_660_000_000)
        try makeLegacyStore { context in
            insertConversation(
                into: context,
                id: conversationId,
                title: "카페 대화",
                members: ["Marco", "Coda"],
                pins: [1.5, 3.0],
                recordedDate: recordedDate,
                fileName: "2022-08-09_08-06-40.m4a"
            )
            insertNote(into: context, id: noteId, category: "sentence", references: [conversationId])
            insertNote(into: context, id: UUID(), category: "vocabulary", references: [])
        }

        // when
        let outcome = try makeSUT().migrateIfNeeded(into: modelContext)

        // then
        #expect(outcome == .migrated(conversations: 1, notes: 2))
        let conversation = try #require(try modelContext.fetch(FetchDescriptor<Conversation>()).first)
        #expect(conversation.id == conversationId)
        #expect(conversation.title == "카페 대화")
        #expect(conversation.createdDate == recordedDate)
        #expect(conversation.pins == [1.5, 3.0])
        #expect(Set(conversation.parties.map(\.name)) == ["Marco", "Coda"])
        #expect(conversation.noteIds == [noteId])
        #expect(conversation.recordFileName == "2022-08-09_08-06-40.m4a")

        let notes = try modelContext.fetch(FetchDescriptor<Note>())
        #expect(notes.count == 2)
        #expect(notes.first { $0.id == noteId }?.category == .sentence)
    }

    @Test("v1 녹음 파일을 v2 녹음 디렉토리로 옮겨 다시 연결한다")
    func movesRecordFileToNewDirectory() throws {
        defer { cleanUp() }

        // given
        let fileName = "2022-08-09_08-06-40.m4a"
        let legacyFileURL = legacyRecordDirectory.appendingPathComponent(fileName)
        try Data("recording".utf8).write(to: legacyFileURL)
        try makeLegacyStore { context in
            insertConversation(into: context, fileName: fileName)
        }

        // when
        _ = try makeSUT().migrateIfNeeded(into: modelContext)

        // then
        let conversation = try #require(try modelContext.fetch(FetchDescriptor<Conversation>()).first)
        let migratedFileURL = try #require(fileStore.fileURL(of: conversation.recordFileName))
        #expect(fileStore.fileExists(at: migratedFileURL))
        #expect(!fileStore.fileExists(at: legacyFileURL))
    }

    @Test("같은 녹음 파일을 가리키는 대화는 파일을 복사해 각자 갖는다")
    func copiesSharedRecordFile() throws {
        defer { cleanUp() }

        // given
        let fileName = "20220809_0806.m4a"
        try Data("recording".utf8).write(to: legacyRecordDirectory.appendingPathComponent(fileName))
        try makeLegacyStore { context in
            insertConversation(into: context, title: "첫 번째", fileName: fileName)
            insertConversation(into: context, title: "두 번째", fileName: fileName)
        }

        // when
        _ = try makeSUT().migrateIfNeeded(into: modelContext)

        // then
        let conversations = try modelContext.fetch(FetchDescriptor<Conversation>())
        let fileURLs = try conversations.map { try #require(fileStore.fileURL(of: $0.recordFileName)) }
        #expect(Set(fileURLs).count == 2)
        #expect(fileURLs.allSatisfy { fileStore.fileExists(at: $0) })
        #expect(try fileURLs.map { try Data(contentsOf: $0) }.allSatisfy { $0 == Data("recording".utf8) })

        // when
        try ConversationDeletionService(fileStore: fileStore).delete(conversations[0], from: modelContext)

        // then
        #expect(fileStore.fileExists(at: fileURLs[1]))
    }

    @Test("한 번 옮기면 다시 실행해도 중복되지 않는다")
    func migratesOnlyOnce() throws {
        defer { cleanUp() }

        // given
        try makeLegacyStore { context in
            insertConversation(into: context, fileName: "a.m4a")
        }
        let sut = makeSUT()
        _ = try sut.migrateIfNeeded(into: modelContext)

        // when
        let outcome = try sut.migrateIfNeeded(into: modelContext)

        // then
        #expect(outcome == .alreadyMigrated)
        #expect(try modelContext.fetch(FetchDescriptor<Conversation>()).count == 1)
    }

    @Test("완료 표시가 없어도 이미 옮긴 대화는 다시 넣지 않는다")
    func skipsExistingConversations() throws {
        defer { cleanUp() }

        // given
        try makeLegacyStore { context in
            insertConversation(into: context, fileName: "a.m4a")
        }
        _ = try makeSUT().migrateIfNeeded(into: modelContext)
        userDefaults.removeObject(forKey: .Key.isLegacyStoreMigrated)

        // when
        let outcome = try makeSUT().migrateIfNeeded(into: modelContext)

        // then
        #expect(outcome == .migrated(conversations: 0, notes: 0))
        #expect(try modelContext.fetch(FetchDescriptor<Conversation>()).count == 1)
    }

    @Test("v1 저장소가 없으면 완료로 표시하고 아무것도 하지 않는다")
    func noLegacyStore() throws {
        defer { cleanUp() }

        // when
        let outcome = try makeSUT().migrateIfNeeded(into: modelContext)

        // then
        #expect(outcome == .noLegacyStore)
        #expect(userDefaults.bool(forKey: .Key.isLegacyStoreMigrated))
    }

    @Test("v1 저장소를 읽지 못하면 원본을 보존하고 다음 실행에 다시 시도한다")
    func unreadableStoreKeepsOriginal() throws {
        defer { cleanUp() }

        // given
        let original = Data("not a sqlite store".utf8)
        try original.write(to: storeURL)

        // when, then
        #expect(throws: LegacyStoreMigrator.MigrationError.self) {
            try makeSUT().migrateIfNeeded(into: modelContext)
        }
        #expect(!userDefaults.bool(forKey: .Key.isLegacyStoreMigrated))
        #expect(try Data(contentsOf: storeURL) == original)
    }

}

private extension LegacyStoreMigratorTests {

    func makeSUT() -> LegacyStoreMigrator {
        LegacyStoreMigrator(
            dependency: .init(
                storeURL: storeURL,
                modelURL: Bundle.main.url(forResource: LegacyStoreMigrator.modelName, withExtension: "momd"),
                legacyRecordDirectories: [legacyRecordDirectory],
                fileStore: fileStore,
                userDefaults: userDefaults,
                fileManager: .default
            )
        )
    }

    func makeLegacyStore(_ insert: (NSManagedObjectContext) -> Void) throws {
        let modelURL = try #require(Bundle.main.url(forResource: LegacyStoreMigrator.modelName, withExtension: "momd"))
        let model = try #require(NSManagedObjectModel(contentsOf: modelURL))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(type: .sqlite, at: storeURL)

        let context = NSManagedObjectContext(.mainQueue)
        context.persistentStoreCoordinator = coordinator
        insert(context)
        try context.save()
        try coordinator.remove(store)
    }

    func insertConversation(
        into context: NSManagedObjectContext,
        id: UUID = .init(),
        title: String = "대화",
        members: [String] = [],
        pins: [TimeInterval] = [],
        recordedDate: Date = .now,
        fileName: String
    ) {
        let object = NSEntityDescription.insertNewObject(forEntityName: "ConversationEntity", into: context)
        object.setValue(id, forKey: "id")
        object.setValue(title, forKey: "title")
        object.setValue("주제", forKey: "topic")
        object.setValue(members, forKey: "members")
        object.setValue(pins, forKey: "pins")
        object.setValue(recordedDate, forKey: "recordedDate")
        object.setValue(
            URL(filePath: "/var/mobile/Containers/Data/Application/OLD-UUID/Documents/Records/\(fileName)"),
            forKey: "recordFilePath"
        )
    }

    func insertNote(
        into context: NSManagedObjectContext,
        id: UUID,
        category: String,
        references: [UUID]
    ) {
        let object = NSEntityDescription.insertNewObject(forEntityName: "NoteEntity", into: context)
        object.setValue(id, forKey: "id")
        object.setValue("original", forKey: "original")
        object.setValue("번역", forKey: "translation")
        object.setValue(category, forKey: "category")
        object.setValue(references, forKey: "references")
        object.setValue(Date.now, forKey: "createdDate")
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: baseURL)
    }

}
