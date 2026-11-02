
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
        await store.receive(\.notes.load)
        await store.receive(\.playbackPanel.prepare)
        await store.receive(\.notes.response.notesLoaded)
        await store.receive(\.playbackPanel.response.prepared)
        await store.receive(\.playbackPanel.delegate.failed) {
            $0.alert = .playbackFailed(
                message: "녹음 파일을 준비하지 못했습니다"
            )
        }
    }

    @Test("노트를 선택하면 노트 상세 화면 상태를 생성한다")
    func noteSelectionCreatesNoteDetailState() async {
        // given
        let store = makeStore()

        // when, then
        await store.send(.notes(.view(.noteSelected(note.id))))
        await store.receive(\.notes.delegate.noteSelected) {
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
        await store.receive(\.notes.load)
        await store.receive(\.notes.response.notesLoaded) {
            $0.notes.notes = [note]
        }
    }

    @Test("수정 직후 화면을 닫아도 최신 내용을 저장한다")
    func disappearingFlushesPendingConversationUpdate() async {
        // given
        let updates = ConversationUpdates()
        let clock = TestClock<Duration>()
        var state: ConversationDetailScreen.Root.Feature.State = .init(
            conversationID: conversation.id
        )
        state.conversation = conversation
        let store = makeStore(
            state: state,
            clock: clock,
            update: { await updates.append($0) }
        )

        // when, then
        await store.send(.view(.titleChanged("수정된 제목")))
        await store.receive(\.conversationUpdateRequested) {
            $0.conversation?.title = "수정된 제목"
            $0.conversationUpdateRevision = 1
        }
        await store.send(.view(.disappeared))
        await store.receive(\.conversationPersistenceRequested)
        await store.receive(\.notes.cancel)
        await store.receive(\.playbackPanel.finish)
        await store.receive(\.response.conversationPersisted) {
            $0.persistedConversationRevision = 1
        }
        #expect(await updates.values().map(\.title) == ["수정된 제목"])
    }

}

private extension ConversationDetailScreenPresentationTests {

    func makeStore(
        state: ConversationDetailScreen.Root.Feature.State? = nil,
        notes: [Note] = [],
        clock: TestClock<Duration>? = nil,
        update: @escaping @Sendable (Conversation) async throws -> Void = { _ in }
    ) -> TestStoreOf<ConversationDetailScreen.Root.Feature> {
        .init(
            initialState: state ?? .init(conversationID: conversation.id),
            reducer: { ConversationDetailScreen.Root.Feature() },
            withDependencies: {
                if let clock {
                    $0.continuousClock = clock
                }
                $0.managingConversationUsecase = .init(
                    conversations: { .success([]) },
                    conversation: { _ in .success(conversation) },
                    notes: { _ in .success(notes) },
                    update: update,
                    deleteConversations: { _ in .success(()) },
                    addNote: { _, _ in conversation },
                    deleteNotes: { _, _ in conversation }
                )
                $0.playingRecordUsecase.prepare = { _ in
                    throw TestError.failed
                }
                $0.playingRecordUsecase.finish = {}
            }
        )
    }

    enum TestError: Error {
        case failed
    }

    actor ConversationUpdates {
        private var conversations: [Conversation] = []

        func append(_ conversation: Conversation) {
            conversations.append(conversation)
        }

        func values() -> [Conversation] {
            conversations
        }
    }

}
