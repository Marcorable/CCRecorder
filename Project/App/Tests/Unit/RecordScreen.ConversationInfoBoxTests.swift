
import Testing

import ComposableArchitecture

@testable import CCRecorder

@Suite("녹음 화면 대화 정보 Feature")
@MainActor
struct RecordScreenConversationInfoBoxTests {}

extension RecordScreenConversationInfoBoxTests {

    @Test("제목 지우기 버튼을 누르면 제목을 비운다")
    func clearTitle() async {
        // given
        let store = makeStore(title: "카페 대화")

        // when, then
        await store.send(.view(.clearTitleButtonTapped)) {
            $0.title = ""
        }
    }

    @Test("참여자를 추가하면 입력을 비우고 목록 앞에 넣는다")
    func addParty() async {
        // given
        let store = makeStore(
            partyName: "Jane",
            parties: ["Tom"]
        )

        // when, then
        await store.send(.view(.addParty)) {
            $0.partyName = ""
            $0.parties = ["Jane", "Tom"]
        }
    }

    @Test("참여자 입력이 비어 있으면 목록을 변경하지 않는다")
    func addEmptyParty() async {
        // given
        let store = makeStore(parties: ["Tom"])

        // when
        await store.send(.view(.addParty))

        // then
        #expect(store.state.parties == ["Tom"])
    }

    @Test("참여자 삭제 버튼을 누르면 해당 참여자를 제거한다")
    func removeParty() async {
        // given
        let store = makeStore(parties: ["Tom", "Jane"])

        // when, then
        await store.send(.view(.removePartyButtonTapped(0))) {
            $0.parties = ["Jane"]
        }
    }

    @Test("편집 버튼을 누르면 편집 상태를 전환한다")
    func toggleEditing() async {
        // given
        let store = makeStore()

        // when, then
        await store.send(.view(.editingButtonTapped)) {
            $0.isEditing = true
        }
    }

}

private extension RecordScreenConversationInfoBoxTests {

    func makeStore(
        title: String = "영어 회화",
        partyName: String = "",
        parties: [String] = []
    ) -> TestStoreOf<RecordScreen.ConversationInfoBox.Feature> {
        .init(
            initialState: .init(
                title: title,
                partyName: partyName,
                parties: parties
            ),
            reducer: { RecordScreen.ConversationInfoBox.Feature() }
        )
    }

}
