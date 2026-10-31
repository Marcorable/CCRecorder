
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

    @Test("화면이 나타나면 ID로 Conversation을 불러온다")
    func appearedLoadsConversationByID() async {
        // given
        let store = makeStore()

        // when, then
        await store.send(.view(.appeared))
        await store.receive(\.response.conversationLoaded) {
            $0.conversation = conversation
        }
        await store.receive(\.response.notesLoaded)
        await store.receive(\.response.playbackPrepared) {
            $0.playbackFailure = .prepareFailed
        }
    }

    @Test("노트를 선택하면 노트 상세 화면 상태를 생성한다")
    func noteSelectionCreatesNoteDetailState() async {
        // given
        let store = makeStore()

        // when, then
        await store.send(.view(.noteSelected(note.id))) {
            $0.noteDetail = .init(noteID: note.id)
        }
    }

    @Test("노트 상세 화면을 닫으면 노트 목록을 다시 불러온다")
    func noteDetailDismissReloadsNotes() async {
        // given
        var state: ConversationDetailScreen.Root.Feature.State = .init(
            conversationID: conversation.id
        )
        state.conversation = conversation
        state.noteDetail = .init(noteID: note.id)
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
            initialState: state ?? .init(conversationID: conversation.id),
            reducer: { ConversationDetailScreen.Root.Feature() },
            withDependencies: {
                $0.managingConversationUsecase = .init(
                    conversations: { .success([]) },
                    conversation: { _ in .success(conversation) },
                    notes: { _ in .success(notes) },
                    update: { _ in },
                    deleteConversations: { _ in .success(()) },
                    addNote: { _, conversation in conversation },
                    deleteNotes: { _, conversation in conversation }
                )
                $0.playingRecordUsecase.prepare = { _ in
                    throw TestError.failed
                }
            }
        )
    }

    enum TestError: Error {
        case failed
    }

}
