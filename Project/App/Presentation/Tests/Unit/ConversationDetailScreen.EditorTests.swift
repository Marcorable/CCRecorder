
import Testing
import Foundation

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("대화 상세 Editor")
@MainActor
struct ConversationDetailScreenEditorTests {
    private let conversationID = UUID()
    private let note: Note = .init(
        id: .init(),
        createdDate: .init(timeIntervalSince1970: 0),
        original: "Hello",
        translation: "안녕하세요",
        category: .vocabulary
    )
}

extension ConversationDetailScreenEditorTests {

    @Test("Conversation 로드 사건을 받으면 표시 상태를 갱신하고 노트를 불러온다")
    func loadedConversationUpdatesViewStateAndLoadsNotes() async {
        // given
        let createdDate = Date(timeIntervalSince1970: 0)
        let party: ConversationDetailScreen.Editor.Feature.State.Party = .init(
            id: .init(),
            name: "Marco"
        )
        let store = makeStore(notes: [note])

        // when, then
        await store.send(.parent(.conversationLoaded(
            createdDate: createdDate,
            title: "영어 회화",
            topic: "인사",
            parties: [party]
        ))) {
            $0.createdDate = createdDate
            $0.title = "영어 회화"
            $0.topic = "인사"
            $0.parties = [party]
            $0.isLoading = true
        }
        await store.receive(\.response.notesLoading)
        await store.receive(\.response.notesLoaded) {
            $0.isLoading = false
            $0.rows = [self.row]
        }
    }

    @Test("제목을 변경하면 Editor 상태를 갱신하고 부모에 변경을 알린다")
    func titleChangeUpdatesStateAndDelegates() async {
        // given
        var state = ConversationDetailScreen.Editor.Feature.State(
            conversationID: conversationID
        )
        state.title = "이전 제목"
        let store = makeStore(state: state)

        // when, then
        await store.send(.view(.titleChanged("새 제목"))) {
            $0.title = "새 제목"
        }
        await store.receive(\.delegate.titleChanged)
    }

    @Test("노트를 추가하면 입력을 비우고 변경된 노트 ID와 표시 rows를 갱신한다")
    func noteAdditionUpdatesNoteIDsAndRows() async {
        // given
        let addition = NoteAdditionSpy()
        let conversation = Conversation(
            createdDate: .init(timeIntervalSince1970: 0),
            pins: [],
            title: "영어 회화",
            topic: "인사",
            noteIds: [note.id],
            parties: []
        )
        var state = ConversationDetailScreen.Editor.Feature.State(
            conversationID: conversationID
        )
        state.noteInput = "Hello"
        let store = makeStore(
            state: state,
            notes: [note],
            addNote: { input, _ in
                await addition.append(input)
                return conversation
            }
        )
        store.exhaustivity = .off(showSkippedAssertions: false)

        // when, then
        await store.send(.view(.noteAdded)) {
            $0.noteInput = ""
            $0.isLoading = true
        }
        await store.receive(\.response.noteAdding)
        await store.receive(\.response.noteAdded)
        await store.receive(\.delegate.noteIDsUpdated)
        await store.receive(\.response.notesLoaded) {
            $0.isLoading = false
            $0.rows = [self.row]
        }
        #expect(await addition.values() == ["Hello"])
    }

    @Test("노트 저장 중에는 추가 요청을 다시 실행하지 않는다")
    func noteAdditionIsIgnoredWhileLoading() async {
        // given
        var state = ConversationDetailScreen.Editor.Feature.State(
            conversationID: conversationID
        )
        state.noteInput = "Hello"
        state.isLoading = true
        let store = makeStore(state: state)

        // when, then
        await store.send(.view(.noteAdded))
    }

    @Test("노트를 삭제하면 변경된 노트 ID와 표시 rows를 갱신한다")
    func noteDeletionUpdatesNoteIDsAndRows() async {
        // given
        let deletion = NoteDeletionSpy()
        var state = ConversationDetailScreen.Editor.Feature.State(
            conversationID: conversationID
        )
        state.rows = [row]
        let store = makeStore(
            state: state,
            deleteNotes: { ids, _ in
                await deletion.append(ids)
                return .init(
                    createdDate: .init(timeIntervalSince1970: 0),
                    pins: [],
                    title: "영어 회화",
                    topic: "인사",
                    noteIds: [],
                    parties: []
                )
            }
        )

        // when, then
        await store.send(.view(.notesDeleted([note.id]))) {
            $0.isLoading = true
        }
        await store.receive(\.response.notesDeleting)
        await store.receive(\.response.notesDeleted)
        await store.receive(\.delegate.noteIDsUpdated)
        await store.receive(\.response.notesLoading)
        await store.receive(\.response.notesLoaded) {
            $0.isLoading = false
            $0.rows = []
        }
        #expect(await deletion.values() == [[note.id]])
    }

}

private extension ConversationDetailScreenEditorTests {

    var row: NoteBoard.Row.ViewModel {
        .init(
            id: note.id,
            original: note.original,
            translation: note.translation,
            isVocabulary: true
        )
    }

    func makeStore(
        state: ConversationDetailScreen.Editor.Feature.State? = nil,
        notes: [Note] = [],
        addNote: @escaping @Sendable (
            String,
            Conversation.ID
        ) async throws -> Conversation = { _, _ in
            .init(
                createdDate: .init(timeIntervalSince1970: 0),
                pins: [],
                title: "",
                topic: "",
                parties: []
            )
        },
        deleteNotes: @escaping @Sendable (
            [Note.ID],
            Conversation.ID
        ) async throws -> Conversation = { _, _ in
            .init(
                createdDate: .init(timeIntervalSince1970: 0),
                pins: [],
                title: "",
                topic: "",
                parties: []
            )
        }
    ) -> TestStoreOf<ConversationDetailScreen.Editor.Feature> {
        .init(
            initialState: state ?? .init(conversationID: conversationID),
            reducer: { ConversationDetailScreen.Editor.Feature() },
            withDependencies: {
                $0.managingConversationUsecase = .init(
                    conversations: { .success([]) },
                    conversation: { _ in .success(nil) },
                    notes: { _ in .success(notes) },
                    update: { _ in },
                    deleteConversations: { _ in .success(()) },
                    addNote: addNote,
                    deleteNotes: deleteNotes
                )
            }
        )
    }

    actor NoteAdditionSpy {
        private var inputs: [String] = []

        func append(_ input: String) {
            inputs.append(input)
        }

        func values() -> [String] {
            inputs
        }
    }

    actor NoteDeletionSpy {
        private var ids: [[Note.ID]] = []

        func append(_ ids: [Note.ID]) {
            self.ids.append(ids)
        }

        func values() -> [[Note.ID]] {
            ids
        }
    }

}
