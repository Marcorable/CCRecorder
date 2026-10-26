
import Testing
import Foundation

import Data
import Domain

extension DataRepositoryTests {

    @Suite("Conversation 저장소")
    @MainActor
    struct ConversationRepositoryConcreteTests {
        private let repository: any ConversationRepository

        init() throws {
            try DataFactory.setup(true)
            self.repository = DataFactory.makeConversationRepository()
        }
    }

}

extension DataRepositoryTests.ConversationRepositoryConcreteTests {

    @Test("저장된 Conversation이 없으면 빈 목록을 반환한다")
    func readReturnsEmptyWhenNoConversationExists() async throws {
        // when
        let conversations = try await repository.read()

        // then
        #expect(conversations.isEmpty)
    }

    @Test("Conversation을 생성하면 Party 스냅샷과 함께 반환한다")
    func readReturnsCreatedConversation() async throws {
        // given
        let createdDate = Date(timeIntervalSince1970: 1_000)
        let conversation = Conversation(
            createdDate: createdDate,
            recordFileName: "record.m4a",
            pins: [1, 2],
            title: "Title",
            topic: "Topic",
            parties: [
                .init(name: "Marco"),
                .init(name: "Coda"),
            ]
        )
        try await repository.create(conversation)

        // when
        let restoredConversation = try #require(
            try await repository.read().first { $0.id == conversation.id }
        )

        // then
        #expect(restoredConversation.createdDate == createdDate)
        #expect(restoredConversation.recordFileName == "record.m4a")
        #expect(restoredConversation.pins == [1, 2])
        #expect(restoredConversation.title == "Title")
        #expect(restoredConversation.topic == "Topic")
        #expect(restoredConversation.noteIds.isEmpty)
        #expect(
            restoredConversation.parties.map(\.name)
                == ["Marco", "Coda"]
        )
        #expect(restoredConversation.parties.allSatisfy({ !$0.isAvailable }))
    }

    @Test("Conversation을 수정하면 변경된 값을 반환한다")
    func updateChangesConversation() async throws {
        // given
        let createdConversation = Conversation(
            createdDate: .init(timeIntervalSince1970: 1_000),
            recordFileName: "record.m4a",
            pins: [],
            title: "Title",
            topic: "Topic",
            parties: [.init(name: "Marco")]
        )
        try await repository.create(createdConversation)
        var conversation = try #require(
            try await repository.read().first {
                $0.id == createdConversation.id
            }
        )
        conversation.title = "Updated Title"
        conversation.topic = "Updated Topic"
        conversation.pins = [3]
        conversation.noteIds = [.init()]

        // when
        try await repository.update(conversation)

        // then
        let restoredConversation = try #require(
            try await repository.read().first {
                $0.id == createdConversation.id
            }
        )
        #expect(restoredConversation.title == "Updated Title")
        #expect(restoredConversation.topic == "Updated Topic")
        #expect(restoredConversation.pins == [3])
        #expect(restoredConversation.noteIds == conversation.noteIds)
        #expect(restoredConversation.parties == conversation.parties)
    }

    @Test("선택한 Conversation을 삭제하면 목록에서 제거한다")
    func deleteRemovesSelectedConversations() async throws {
        // given
        let deletedConversation = Conversation(
            createdDate: .init(),
            recordFileName: "deleted.m4a",
            pins: [],
            title: "Deleted",
            topic: "",
            parties: []
        )
        let remainingConversation = Conversation(
            createdDate: .init(),
            recordFileName: "remaining.m4a",
            pins: [],
            title: "Remaining",
            topic: "",
            parties: []
        )
        try await repository.create(deletedConversation)
        try await repository.create(remainingConversation)

        // when
        try await repository.delete(ids: [deletedConversation.id])

        // then
        let conversations = try await repository.read()
        #expect(!conversations.contains { $0.id == deletedConversation.id })
        #expect(conversations.contains { $0.id == remainingConversation.id })
    }

}
