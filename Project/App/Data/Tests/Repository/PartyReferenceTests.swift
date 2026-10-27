
import Testing
import Foundation

import Domain
@testable import Data

@Suite("Party 참조")
@MainActor
struct PartyReferenceTests {
    private let conversationRepository: any ConversationRepository
    private let partyRepository: any PartyRepository

    init() throws {
        let modelContainer = try makeTestModelContainer()
        self.conversationRepository = ConversationRepositoryConcrete(
            modelContainer: modelContainer
        )
        self.partyRepository = PartyRepositoryConcrete(
            modelContainer: modelContainer
        )
    }
}

extension PartyReferenceTests {

    @Test("현재 Party는 최신 이름과 선택 가능한 상태로 반환한다")
    func currentPartyUsesLatestName() async throws {
        // given
        let party = Party(name: "Marco")
        try await partyRepository.create(party)
        let conversation = Conversation(
            createdDate: Date(timeIntervalSince1970: 1_000),
            recordFileName: "record.m4a",
            pins: [],
            title: "Title",
            topic: "Topic",
            parties: [party]
        )
        try await conversationRepository.create(conversation)
        var updatedParty = party
        updatedParty.name = "Updated Marco"
        try await partyRepository.update(updatedParty)

        // when
        let restoredConversation = try #require(
            try await conversationRepository.read().first {
                $0.id == conversation.id
            }
        )

        // then
        let restoredParty = try #require(restoredConversation.parties.first)
        #expect(restoredParty.id == party.id)
        #expect(restoredParty.name == "Updated Marco")
        #expect(restoredParty.isAvailable)
    }

    @Test("Party를 삭제하면 Conversation에는 이름과 선택 불가 상태가 남는다")
    func deletedPartyLeavesNameSnapshot() async throws {
        // given
        let party = Party(name: "Marco")
        try await partyRepository.create(party)
        let conversation = Conversation(
            createdDate: Date(timeIntervalSince1970: 1_000),
            recordFileName: "record.m4a",
            pins: [],
            title: "Title",
            topic: "Topic",
            parties: [party]
        )
        try await conversationRepository.create(conversation)

        // when
        try await partyRepository.delete(ids: [party.id])

        // then
        let restoredConversation = try #require(
            try await conversationRepository.read().first {
                $0.id == conversation.id
            }
        )
        let restoredParty = try #require(restoredConversation.parties.first)
        #expect(restoredParty.id == party.id)
        #expect(restoredParty.name == "Marco")
        #expect(!restoredParty.isAvailable)
        #expect(try await partyRepository.read().isEmpty)
    }

}
