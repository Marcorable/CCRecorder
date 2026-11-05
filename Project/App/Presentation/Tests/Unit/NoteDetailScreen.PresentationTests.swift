
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("노트 상세 화면 Presentation")
@MainActor
struct NoteDetailScreenPresentationTests {
    private let note: Note = .init(
        createdDate: .init(timeIntervalSince1970: 0),
        original: "Hello",
        translation: "안녕하세요",
        category: .vocabulary
    )
}

extension NoteDetailScreenPresentationTests {

    @Test("화면이 나타나면 ID로 Note를 불러온다")
    func appearedLoadsNoteByID() async {
        // given
        let store = makeStore(note: note)
        store.exhaustivity = .off(showSkippedAssertions: false)

        // when, then
        await store.send(.view(.appeared))
        await store.receive(\.response.noteLoading)
        await store.receive(\.response.noteLoaded) {
            $0.isLoading = false
            $0.original = self.note.original
            $0.translation = self.note.translation
        }
        #expect(store.state.isVocabulary == true)
    }

    @Test("ID에 해당하는 Note가 없으면 불러오기 실패 상태가 된다")
    func missingNoteShowsLoadFailure() async {
        // given
        let store = makeStore(note: nil)

        // when, then
        await store.send(.view(.appeared))
        await store.receive(\.response.noteLoading)
        await store.receive(\.response.noteLoaded) {
            $0.isLoading = false
        }
        #expect(store.state.isVocabulary == nil)
    }

    @Test("수정한 노트는 Action에서 저장 값과 카테고리를 확정한다")
    func saveBuildsUpdatedNoteInAction() async {
        // given
        let translation = note.translation
        let store = makeStore(
            note: note,
            updateNote: { updatedNote in
                #expect(updatedNote.original == "This is updated")
                #expect(updatedNote.translation == translation)
                #expect(updatedNote.category == .sentence)
                return .failure(.data(TestError()))
            }
        )
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.view(.appeared))
        await store.receive(\.response.noteLoading)
        await store.receive(\.response.noteLoaded) {
            $0.isLoading = false
            $0.original = self.note.original
            $0.translation = self.note.translation
        }
        await store.send(.binding(.set(\.original, "This is updated"))) {
            $0.original = "This is updated"
        }

        // when, then
        await store.send(.view(.saveButtonTapped)) {
            $0.isLoading = true
        }
        await store.receive(\.response.noteUpdating)
        await store.receive(\.response.noteUpdated) {
            $0.isLoading = false
            $0.alert = .saveFailed
        }
    }

    @Test("수정한 노트 저장에 성공하면 화면을 닫는다")
    func successfulSaveDismissesScreen() async {
        // given
        let dismissal = NoteDetailDismissSpy()
        let store = makeStore(
            note: note,
            dismiss: DismissEffect {
                dismissal.call()
            }
        )
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.view(.appeared))
        await store.receive(\.response.noteLoading)
        await store.receive(\.response.noteLoaded) {
            $0.isLoading = false
            $0.original = self.note.original
            $0.translation = self.note.translation
        }
        await store.send(.binding(.set(\.translation, "반갑습니다"))) {
            $0.translation = "반갑습니다"
        }

        // when, then
        await store.send(.view(.saveButtonTapped)) {
            $0.isLoading = true
        }
        await store.receive(\.response.noteUpdating)
        await store.receive(\.response.noteUpdated) {
            $0.isLoading = false
        }
        await store.finish()
        #expect(dismissal.callCount == 1)
    }

}

private extension NoteDetailScreenPresentationTests {

    func makeStore(
        note: Note?,
        dismiss: DismissEffect = .init {},
        updateNote: @escaping @Sendable (Note) async -> Result<Void, DomainError> = { _ in
            .success(())
        }
    ) -> TestStoreOf<NoteDetailScreen.Root.Feature> {
        .init(
            initialState: .init(noteID: self.note.id),
            reducer: { NoteDetailScreen.Root.Feature() },
            withDependencies: {
                $0.dismiss = dismiss
                $0.managingNoteUsecase.note = { _ in .success(note) }
                $0.managingNoteUsecase.updateNote = updateNote
            }
        )
    }

}

private struct TestError: Error {}

@MainActor
private final class NoteDetailDismissSpy {
    private(set) var callCount = 0

    func call() {
        callCount += 1
    }
}
