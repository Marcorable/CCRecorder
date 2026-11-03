
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

    @Test("마이크 권한이 허용된 상태에서 녹음 버튼을 누르면 녹음 화면 상태를 생성한다")
    func authorizedRecordButtonCreatesRecordState() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .authorized }
            }
        )

        // when, then
        await store.send(.view(.recordButtonTapped)) {
            $0.record = .init()
        }
    }

    @Test("마이크 권한이 정해지지 않은 상태에서 허용하면 녹음 화면 상태를 생성한다")
    func authorizationRequestCreatesRecordStateWhenAuthorized() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .notDetermined }
                $0.audioSession.requestAuthorization = { .authorized }
            }
        )

        // when, then
        await store.send(.view(.recordButtonTapped)) {
            $0.recordingEntryPhase = .requestingAuthorization
        }
        await store.receive(\.response.recordAuthorization) {
            $0.recordingEntryPhase = .idle
            $0.record = .init()
        }
    }

    @Test("마이크 권한 요청을 거부하면 메인 화면에서 권한 안내를 표시한다")
    func authorizationRequestShowsAlertWhenDenied() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .notDetermined }
                $0.audioSession.requestAuthorization = { .denied }
            }
        )

        // when, then
        await store.send(.view(.recordButtonTapped)) {
            $0.recordingEntryPhase = .requestingAuthorization
        }
        await store.receive(\.response.recordAuthorization) {
            $0.recordingEntryPhase = .idle
            $0.alert = .permissionDenied
        }
    }

    @Test("거부된 마이크 권한으로 녹음 버튼을 누르면 메인 화면에서 권한 안내를 표시한다")
    func deniedRecordButtonShowsAlert() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .denied }
            }
        )

        // when, then
        await store.send(.view(.recordButtonTapped)) {
            $0.alert = .permissionDenied
        }
    }

    @Test("설정으로 이동하면 녹음 진입 상태를 유지하지 않는다")
    func openingSettingsLeavesRecordingEntryIdle() async {
        // given
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        state.alert = .permissionDenied
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.openURL = .init { _ in true }
            }
        )

        // when, then
        await store.send(.alert(.presented(.openSettingsTapped))) {
            $0.alert = nil
        }
        #expect(store.state.recordingEntryPhase == .idle)
        #expect(store.state.record == nil)
    }

    @Test("녹음 화면 진입 직전에 권한이 사라지면 화면을 닫고 권한 안내를 표시한다")
    func unavailableAuthorizationFromRecordClosesScreen() async {
        // given
        let spy = CallSpy()
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        state.record = .init()
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.recordingUsecase.cancel = {
                    await spy.call()
                }
            }
        )

        // when, then
        await store.send(.record(.presented(.delegate(.authorizationUnavailable)))) {
            $0.record = nil
            $0.alert = .permissionDenied
        }
        await store.finish()
        #expect(await spy.callCount == 1)
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
        store.exhaustivity = .off(showSkippedAssertions: false)

        // when, then
        await store.send(.noteDetail(.dismiss)) {
            $0.noteDetail = nil
        }
        await store.receive(\.noteList.noteDetailDismissed) {
            $0.noteList.isLoading = true
        }
        await store.receive(\.noteList.response.notesLoaded) {
            $0.noteList.isLoading = false
        }
        #expect(store.state.noteList.rows?.map(\.id) == [note.id])
    }

    @Test("녹음 화면을 닫으면 선택한 노트 목록만 다시 불러온다")
    func recordDismissReloadsSelectedList() async {
        // given
        let spy = CallSpy()
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        state.record = .init()
        state.selectedTab = .noteList
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.managingNoteUsecase.loadNotes = { .success([]) }
                $0.recordingUsecase.cancel = {
                    await spy.call()
                }
            }
        )
        store.exhaustivity = .off(showSkippedAssertions: false)

        // when, then
        await store.send(.record(.dismiss)) {
            $0.record = nil
        }
        await store.receive(\.noteList.view.reload) {
            $0.noteList.isLoading = true
        }
        await store.receive(\.noteList.response.notesLoaded) {
            $0.noteList.isLoading = false
        }
        #expect(store.state.noteList.rows == [])
        #expect(await spy.callCount == 1)
    }

    @Test("저장을 완료한 녹음 화면을 닫으면 녹음을 취소하지 않는다")
    func finishedRecordDismissDoesNotCancelRecording() async {
        // given
        let spy = CallSpy()
        var state: MainScreen.Root.Feature.State = .init()
        state.onboard = nil
        state.record = .init()
        state.record?.phase = .finished
        let store: TestStoreOf<MainScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { MainScreen.Root.Feature() },
            withDependencies: {
                $0.managingConversationUsecase.conversations = { .success([]) }
                $0.recordingUsecase.cancel = {
                    await spy.call()
                }
            }
        )

        // when, then
        await store.send(.record(.dismiss)) {
            $0.record = nil
        }
        await store.receive(\.conversationList.view.reload) {
            $0.conversationList.isLoading = true
        }
        await store.receive(\.conversationList.response.conversationsLoaded) {
            $0.conversationList.isLoading = false
            $0.conversationList.conversations = []
        }
        #expect(await spy.callCount == 0)
    }

}

private actor RouteSpy {
    private(set) var routes: [RootStack.Route] = []

    func push(_ route: RootStack.Route) {
        routes.append(route)
    }
}

private actor CallSpy {
    private(set) var callCount = 0

    func call() {
        callCount += 1
    }
}
