
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("Main 화면 Presentation")
@MainActor
struct MainScreenPresentationTests {}

extension MainScreenPresentationTests {

    @Test("대화를 선택하면 해당 ID의 상세 화면으로 이동한다")
    func conversationSelectionPushesDetail() async {
        // given
        let id = UUID()
        let spy = RouteSpy()
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.navigator.push = {
                    await spy.push($0)
                }
            }
        )

        // when
        await store.send(.conversationList(.delegate(.conversationSelected(id))))

        // then
        #expect(await spy.routes == [.conversationDetail(id)])
    }

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

    @Test("녹음 화면을 닫으면 선택한 노트 목록만 다시 불러온다")
    func recordDismissReloadsSelectedList() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        state.record = .init()
        state.selectedTab = .noteList
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.managingNoteUsecase.loadNotes = { .success([]) }
            }
        )

        // when, then
        await store.send(.record(.dismiss)) {
            $0.record = nil
        }
        await store.receive(\.noteList.view.reload) {
            $0.noteList.isLoading = true
        }
        await store.receive(\.noteList.response.notesLoaded) {
            $0.noteList.isLoading = false
            $0.noteList.notes = []
        }
    }

}

private actor RouteSpy {
    private(set) var routes: [RootStack.Route] = []

    func push(_ route: RootStack.Route) {
        routes.append(route)
    }
}
