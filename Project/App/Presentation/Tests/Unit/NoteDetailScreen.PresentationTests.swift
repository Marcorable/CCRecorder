
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

        // when, then
        await store.send(.view(.appeared))
        await store.receive(\.response.noteLoaded) {
            $0.setLoaded(note)
        }
    }

    @Test("ID에 해당하는 Note가 없으면 불러오기 실패 상태가 된다")
    func missingNoteShowsLoadFailure() async {
        // given
        let store = makeStore(note: nil)

        // when, then
        await store.send(.view(.appeared))
        await store.receive(\.response.noteLoaded) {
            $0.noteLoadFailed = true
        }
    }

    @Test("수정한 노트는 Action에서 저장 값과 카테고리를 확정한다")
    func saveBuildsUpdatedNoteInAction() async {
        // given
        var state = NoteDetailScreen.Root.Feature.State(noteID: note.id)
        state.setLoaded(note)
        state.original = "This is updated"
        let translation = note.translation
        let store = TestStore(
            initialState: state,
            reducer: { NoteDetailScreen.Root.Feature() },
            withDependencies: {
                $0.managingNoteUsecase.updateNote = { updatedNote in
                    #expect(updatedNote.original == "This is updated")
                    #expect(updatedNote.translation == translation)
                    #expect(updatedNote.category == .sentence)
                    return .failure(.data(TestError()))
                }
            }
        )

        // when, then
        await store.send(.view(.saveButtonTapped)) {
            $0.isSaving = true
        }
        await store.receive(\.response.noteUpdated) {
            $0.isSaving = false
            $0.alert = .saveFailed
        }
    }

}

private extension NoteDetailScreenPresentationTests {

    func makeStore(
        note: Note?
    ) -> TestStoreOf<NoteDetailScreen.Root.Feature> {
        .init(
            initialState: .init(noteID: self.note.id),
            reducer: { NoteDetailScreen.Root.Feature() },
            withDependencies: {
                $0.managingNoteUsecase.note = { _ in .success(note) }
            }
        )
    }

}

private struct TestError: Error {}
