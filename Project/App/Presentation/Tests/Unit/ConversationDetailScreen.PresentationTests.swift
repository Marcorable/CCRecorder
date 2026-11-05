
import Testing
import Foundation

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

    @Test("화면이 나타나면 Conversation을 한 번 불러와 Editor와 재생 패널에 필요한 값만 전달한다")
    func appearedLoadsConversationByID() async {
        // given
        let store = makeStore(notes: [note])
        store.exhaustivity = .off(showSkippedAssertions: false)

        // when, then
        await store.send(.view(.appeared))
        await store.receive(\.response.conversationLoading)
        await store.receive(\.response.conversationLoaded)
        await store.receive(\.editor.parent.conversationLoaded) {
            $0.editor.createdDate = self.conversation.createdDate
            $0.editor.title = self.conversation.title
            $0.editor.topic = self.conversation.topic
        }
        await store.receive(\.editor.response.notesLoaded) {
            $0.editor.rows = [self.row]
        }
        await store.receive(\.playbackPanel.delegate.failed) {
            $0.alert = .playbackFailed(
                message: "녹음 파일을 준비하지 못했습니다"
            )
        }
    }

    @Test("Editor가 노트 선택을 알리면 노트 상세 화면 상태를 생성한다")
    func noteSelectionCreatesNoteDetailState() async {
        // given
        let store = makeStore()

        // when, then
        await store.send(.editor(.delegate(.noteSelected(note.id)))) {
            $0.noteDetail = .init(noteID: self.note.id)
        }
    }

    @Test("재생 인터럽션 알림에서 닫기를 누르면 상세 화면을 닫는다")
    func interruptionAlertClosePopsDetail() async {
        // given
        let navigation = NavigationSpy()
        let store = makeStore(
            pop: { await navigation.pop() }
        )

        // when, then
        await store.send(.playbackPanel(.delegate(.interrupted))) {
            $0.alert = .playbackInterrupted
        }
        await store.send(.alert(.presented(.close))) {
            $0.alert = nil
        }
        #expect(await navigation.popCallCount == 1)
    }

    @Test("재생 인터럽션 알림에서 확인을 누르면 화면을 유지한다")
    func interruptionAlertConfirmationKeepsDetail() async {
        // given
        let navigation = NavigationSpy()
        let store = makeStore(
            pop: { await navigation.pop() }
        )
        await store.send(.playbackPanel(.delegate(.interrupted))) {
            $0.alert = .playbackInterrupted
        }

        // when, then
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        #expect(await navigation.popCallCount == 0)
    }

    @Test("노트 상세 화면을 닫으면 Editor가 노트 목록을 다시 불러온다")
    func noteDetailDismissReloadsNotes() async {
        // given
        var state: ConversationDetailScreen.Root.Feature.State = .init(
            conversationID: conversation.id
        )
        state.noteDetail = .init(noteID: note.id)
        let store = makeStore(
            state: state,
            notes: [note]
        )

        // when, then
        await store.send(.noteDetail(.dismiss)) {
            $0.noteDetail = nil
        }
        await store.receive(\.editor.parent.noteDetailDismissed) {
            $0.editor.isLoading = true
        }
        await store.receive(\.editor.response.notesLoading)
        await store.receive(\.editor.response.notesLoaded) {
            $0.editor.isLoading = false
            $0.editor.rows = [self.row]
        }
    }

    @Test("수정 직후 화면을 닫아도 최신 내용을 저장한다")
    func disappearingFlushesPendingConversationUpdate() async {
        // given
        let updates = ConversationUpdates()
        let clock = TestClock<Duration>()
        let store = makeStore(
            clock: clock,
            update: { await updates.append($0) }
        )
        await loadConversation(into: store)

        // when, then
        await store.send(.editor(.view(.titleChanged("수정된 제목")))) {
            $0.editor.title = "수정된 제목"
        }
        await store.receive(\.editor.delegate.titleChanged)
        await store.receive(\.response.conversationUpdating) {
            $0.conversationUpdateRevision = 1
        }
        await store.send(.view(.disappeared))
        await store.receive(\.response.conversationPersisting) {
            $0.isPersistingConversation = true
        }
        await store.receive(\.response.conversationPersisted) {
            $0.persistedConversationRevision = 1
            $0.isPersistingConversation = false
        }
        #expect(await updates.values().map(\.title) == ["수정된 제목"])
    }

    @Test("메타데이터 저장 중 발생한 최신 변경을 순서대로 저장한다")
    func conversationUpdatesArePersistedSequentially() async {
        // given
        let updates = SuspendedConversationUpdates()
        let clock = TestClock<Duration>()
        let store = makeStore(
            clock: clock,
            update: { await updates.append($0) }
        )
        await loadConversation(into: store)

        // when, then
        await store.send(.editor(.view(.titleChanged("첫 번째 제목")))) {
            $0.editor.title = "첫 번째 제목"
        }
        await store.receive(\.editor.delegate.titleChanged)
        await store.receive(\.response.conversationUpdating) {
            $0.conversationUpdateRevision = 1
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.response.conversationPersisting) {
            $0.isPersistingConversation = true
        }
        await updates.waitUntilFirstUpdateStarts()

        await store.send(.editor(.view(.titleChanged("두 번째 제목")))) {
            $0.editor.title = "두 번째 제목"
        }
        await store.receive(\.editor.delegate.titleChanged)
        await store.receive(\.response.conversationUpdating) {
            $0.conversationUpdateRevision = 2
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.response.conversationPersisting)
        #expect(await updates.values().map(\.title) == ["첫 번째 제목"])

        await updates.finishFirstUpdate()
        await store.receive(\.response.conversationPersisted) {
            $0.persistedConversationRevision = 1
            $0.isPersistingConversation = false
        }
        await store.receive(\.response.conversationPersisting) {
            $0.isPersistingConversation = true
        }
        await store.receive(\.response.conversationPersisted) {
            $0.persistedConversationRevision = 2
            $0.isPersistingConversation = false
        }
        #expect(
            await updates.values().map(\.title) == [
                "첫 번째 제목",
                "두 번째 제목"
            ]
        )
    }

    @Test("노트 변경 결과를 원본에 병합한 뒤에도 메타데이터 저장이 최신 노트 ID를 유지한다")
    func noteIDsRemainLatestWhenMetadataIsSaved() async {
        // given
        let updates = ConversationUpdates()
        let clock = TestClock<Duration>()
        let store = makeStore(
            clock: clock,
            update: { await updates.append($0) }
        )
        await loadConversation(into: store)

        // when, then
        await store.send(.editor(.delegate(.noteIDsUpdated([note.id]))))
        await store.send(.editor(.view(.titleChanged("수정된 제목")))) {
            $0.editor.title = "수정된 제목"
        }
        await store.receive(\.editor.delegate.titleChanged)
        await store.receive(\.response.conversationUpdating) {
            $0.conversationUpdateRevision = 1
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.response.conversationPersisting) {
            $0.isPersistingConversation = true
        }
        await store.receive(\.response.conversationPersisted) {
            $0.persistedConversationRevision = 1
            $0.isPersistingConversation = false
        }
        #expect(await updates.values().first?.noteIds == [note.id])
    }

}

private extension ConversationDetailScreenPresentationTests {

    var row: NoteBoard.Row.ViewModel {
        .init(
            id: note.id,
            original: note.original,
            translation: note.translation,
            isVocabulary: true
        )
    }

    func makeStore(
        state: ConversationDetailScreen.Root.Feature.State? = nil,
        notes: [Note] = [],
        clock: TestClock<Duration>? = nil,
        update: @escaping @Sendable (Conversation) async throws -> Void = { _ in },
        pop: @escaping @Sendable () async -> Void = {}
    ) -> TestStoreOf<ConversationDetailScreen.Root.Feature> {
        let store: TestStoreOf<ConversationDetailScreen.Root.Feature> = .init(
            initialState: state ?? .init(conversationID: conversation.id),
            reducer: { ConversationDetailScreen.Root.Feature() },
            withDependencies: {
                if let clock {
                    $0.continuousClock = clock
                }
                $0.audioSession.activate = {}
                $0.audioSession.events = {
                    AsyncStream { $0.finish() }
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
                $0.navigator.pop = pop
            }
        )
        return store
    }

    func loadConversation(
        into store: TestStoreOf<ConversationDetailScreen.Root.Feature>
    ) async {
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.response(.conversationLoaded(.success(conversation))))
        await store.receive(\.editor.parent.conversationLoaded) {
            $0.editor.createdDate = self.conversation.createdDate
            $0.editor.title = self.conversation.title
            $0.editor.topic = self.conversation.topic
        }
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

    actor NavigationSpy {
        private(set) var popCallCount = 0

        func pop() {
            popCallCount += 1
        }
    }

    actor SuspendedConversationUpdates {
        private var conversations: [Conversation] = []
        private var firstUpdateContinuation: CheckedContinuation<Void, Never>?
        private var firstUpdateWaiters: [CheckedContinuation<Void, Never>] = []

        func append(_ conversation: Conversation) async {
            conversations.append(conversation)
            if conversations.count == 1 {
                firstUpdateWaiters.forEach({ $0.resume() })
                firstUpdateWaiters.removeAll()
                await withCheckedContinuation { continuation in
                    firstUpdateContinuation = continuation
                }
            }
        }

        func waitUntilFirstUpdateStarts() async {
            guard conversations.isEmpty else {
                return
            }
            await withCheckedContinuation { continuation in
                firstUpdateWaiters.append(continuation)
            }
        }

        func finishFirstUpdate() {
            firstUpdateContinuation?.resume()
            firstUpdateContinuation = nil
        }

        func values() -> [Conversation] {
            conversations
        }
    }

}
