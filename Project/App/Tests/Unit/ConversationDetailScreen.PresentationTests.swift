
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("대화 상세 화면 Presentation")
@MainActor
struct ConversationDetailScreenPresentationTests {
    private let conversation: Conversation = .init(
        createdDate: .init(timeIntervalSince1970: 0),
        pins: [],
        title: "영어 회화",
        topic: "인사",
        parties: []
    )
    private let note: Note = .init(
        createdDate: .init(timeIntervalSince1970: 0),
        original: "Hello",
        translation: "안녕하세요",
        category: .vocabulary
    )
}

extension ConversationDetailScreenPresentationTests {

    @Test("노트를 선택하면 노트 상세 화면 상태를 생성한다")
    func noteSelectionCreatesNoteDetailState() async {
        // given
        let store = makeStore()

        // when, then
        await store.send(.view(.noteSelected(note))) {
            $0.noteDetail = .init(note: note)
        }
    }

    @Test("노트 상세 화면을 닫으면 노트 목록을 다시 불러온다")
    func noteDetailDismissReloadsNotes() async {
        // given
        var state: ConversationDetailScreen.Root.Feature.State = .init(
            conversation: conversation
        )
        state.noteDetail = .init(note: note)
        let store = makeStore(
            state: state,
            notes: [note]
        )

        // when, then
        await store.send(.noteDetail(.dismiss)) {
            $0.noteDetail = nil
        }
        await store.receive(\.response.notesLoaded) {
            $0.notes = [note]
        }
    }

}

private extension ConversationDetailScreenPresentationTests {

    func makeStore(
        state: ConversationDetailScreen.Root.Feature.State? = nil,
        notes: [Note] = []
    ) -> TestStoreOf<ConversationDetailScreen.Root.Feature> {
        .init(
            initialState: state ?? .init(conversation: conversation),
            reducer: { ConversationDetailScreen.Root.Feature() },
            withDependencies: {
                $0.managingConversationUsecase = .init(
                    conversations: { .success([]) },
                    notes: { _ in .success(notes) },
                    update: { _ in },
                    deleteConversations: { _ in .success(()) },
                    addNote: { _, conversation in conversation },
                    deleteNotes: { _, conversation in conversation }
                )
            }
        )
    }

}
