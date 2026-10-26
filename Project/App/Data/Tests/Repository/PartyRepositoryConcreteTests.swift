
import Testing

import Data
import Domain

extension DataRepositoryTests {

    @Suite("Party 저장소")
    @MainActor
    struct PartyRepositoryConcreteTests {
        private let repository: any PartyRepository

        init() throws {
            try DataFactory.setup(true)
            self.repository = DataFactory.makePartyRepository()
        }
    }

}

extension DataRepositoryTests.PartyRepositoryConcreteTests {

    @Test("저장된 Party가 없으면 빈 목록을 반환한다")
    func readReturnsEmptyWhenNoPartyExists() async throws {
        // when
        let parties = try await repository.read()

        // then
        #expect(parties.isEmpty)
    }

    @Test("Party를 생성하면 저장된 값을 반환한다")
    func readReturnsCreatedParty() async throws {
        // given
        let createdParty = Party(name: "Marco")
        try await repository.create(createdParty)

        // when
        let party = try #require(
            try await repository.read().first { $0.id == createdParty.id }
        )

        // then
        #expect(party.name == "Marco")
        #expect(party.isAvailable)
    }

    @Test("Party를 수정하면 변경된 이름을 반환한다")
    func updateChangesParty() async throws {
        // given
        let createdParty = Party(name: "Marco")
        try await repository.create(createdParty)
        var party = try #require(
            try await repository.read().first { $0.id == createdParty.id }
        )
        party.name = "Updated Marco"

        // when
        try await repository.update(party)

        // then
        let updatedParty = try #require(
            try await repository.read().first { $0.id == createdParty.id }
        )
        #expect(updatedParty.name == "Updated Marco")
    }

    @Test("선택한 Party를 삭제하면 목록에서 제거한다")
    func deleteRemovesSelectedParties() async throws {
        // given
        let deletedParty = Party(name: "Deleted")
        let remainingParty = Party(name: "Remaining")
        try await repository.create(deletedParty)
        try await repository.create(remainingParty)

        // when
        try await repository.delete(ids: [deletedParty.id])

        // then
        let parties = try await repository.read()
        #expect(!parties.contains { $0.id == deletedParty.id })
        #expect(parties.contains { $0.id == remainingParty.id })
    }

}
