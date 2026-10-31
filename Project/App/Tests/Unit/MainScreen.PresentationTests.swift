
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("Main 화면 Presentation")
@MainActor
struct MainScreenPresentationTests {}

extension MainScreenPresentationTests {

    @Test("녹음 버튼을 누르면 녹음 화면 상태를 생성한다")
    func recordButtonCreatesRecordState() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() }
        )

        // when, then
        await store.send(.view(.recordButtonTapped)) {
            $0.record = .init()
        }
    }

    @Test("노트를 선택하면 노트 상세 화면 상태를 생성한다")
    func noteSelectionCreatesNoteDetailState() async {
        // given
        let note: Note = .init(
            createdDate: .init(timeIntervalSince1970: 0),
            original: "Hello",
            translation: "안녕하세요",
            category: .vocabulary
        )
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() }
        )

        // when, then
        await store.send(.noteList(.delegate(.noteSelected(note.id)))) {
            $0.noteDetail = .init(noteID: note.id)
        }
    }

    @Test("노트 상세 화면을 닫으면 노트 목록에 닫힘을 전달한다")
    func noteDetailDismissNotifiesNoteList() async {
        // given
        let note: Note = .init(
            createdDate: .init(timeIntervalSince1970: 0),
            original: "Hello",
            translation: "안녕하세요",
            category: .vocabulary
        )
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        state.noteDetail = .init(noteID: note.id)
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.managingNoteUsecase.loadNotes = { .success([note]) }
            }
        )

        // when, then
        await store.send(.noteDetail(.dismiss)) {
            $0.noteDetail = nil
        }
        await store.receive(\.noteList.noteDetailDismissed) {
            $0.noteList.isLoading = true
        }
        await store.receive(\.noteList.response.notesLoaded) {
            $0.noteList.isLoading = false
            $0.noteList.notes = [note]
        }
    }

}
