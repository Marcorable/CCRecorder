
import Foundation
import SwiftData
import Testing

@testable import CCRecorder

@Suite("대화 삭제 파일 생명주기")
@MainActor
struct ConversationDeletionServiceTests {
    private let baseURL: URL
    private let fileStore: RecordFileStore
    private let modelContext: ModelContext
    private let sut: ConversationDeletionService

    init() throws {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Conversation.self, Note.self, Party.self,
            configurations: configuration
        )
        let fileStore = RecordFileStore(baseURL: baseURL)

        self.baseURL = baseURL
        self.fileStore = fileStore
        self.modelContext = .init(container)
        self.sut = .init(fileStore: fileStore)
    }
}

extension ConversationDeletionServiceTests {

    @Test("대화를 삭제하면 녹음 파일과 데이터가 함께 사라진다")
    func deleteRemovesFileAndConversation() throws {
        defer { try? FileManager.default.removeItem(at: baseURL) }

        // given
        let conversation = try makeConversation(fileExists: true)

        // when
        try sut.delete(
            conversation,
            from: modelContext
        )

        // then
        #expect(!fileStore.fileExists(at: conversation.recordFilePath))
        #expect(try fetchConversations().isEmpty)
    }

    @Test("녹음 파일이 이미 없어도 대화 데이터는 삭제된다")
    func deleteWithoutFileRemovesConversation() throws {
        defer { try? FileManager.default.removeItem(at: baseURL) }

        // given
        let conversation = try makeConversation(fileExists: false)

        // when
        try sut.delete(
            conversation,
            from: modelContext
        )

        // then
        #expect(try fetchConversations().isEmpty)
    }

}

private extension ConversationDeletionServiceTests {

    func makeConversation(fileExists: Bool) throws -> Conversation {
        try fileStore.prepareDirectory()
        let recordFileURL = fileStore.makeNewFileURL()
        if fileExists {
            try Data("recording".utf8).write(to: recordFileURL)
        }

        let conversation = Conversation(
            recordFilePath: recordFileURL,
            title: "카페 대화",
            topic: "여행",
            parties: []
        )
        modelContext.insert(conversation)
        try modelContext.save()
        return conversation
    }

    func fetchConversations() throws -> [Conversation] {
        try modelContext.fetch(FetchDescriptor<Conversation>())
    }

}
