
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("녹음 화면 Root Feature")
@MainActor
struct RecordScreenFeatureTests {}

extension RecordScreenFeatureTests {

    @Test("화면 진입과 권한 실패를 RecordingPanel과 연결한다")
    func appearedConnectsRecordingPanelAuthorizationFailure() async {
        // given
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .denied }
            }
        )

        // when, then
        await store.send(.view(.task))
        await store.receive(\.recordingPanel.parent.screenAppeared)
        await store.receive(\.recordingPanel.response.recordingPreparing) {
            $0.recordingPanel.phase = .finished
        }
        await store.receive(\.recordingPanel.delegate.authorizationUnavailable)
        await store.receive(\.delegate.authorizationUnavailable)
    }

    @Test("RecordingPanel의 저장 요청을 확인 Alert로 표시한다")
    func saveRequestShowsConfirmationAlert() async {
        // given
        var state: RecordScreen.Root.Feature.State = .init()
        state.recordingPanel.phase = .paused
        state.recordingPanel.currentTime = 3
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() }
        )

        // when, then
        await store.send(.recordingPanel(.view(.requestSaveButtonTapped)))
        await store.receive(\.recordingPanel.delegate.saveRequested) {
            $0.alert = .confirmSave
        }
    }

    @Test("녹음 취소를 확정하면 녹음물을 폐기한 뒤 화면을 닫는다")
    func confirmedCancellationDiscardsRecordingBeforeDismissal() async {
        // given
        let cancellation = CallSpy()
        let dismissal = DismissSpy()
        var state: RecordScreen.Root.Feature.State = .init(
            recordingPanel: .init(
                phase: .recording,
                currentTime: 3
            )
        )
        state.alert = .confirmCancel
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.dismiss = DismissEffect {
                    dismissal.call()
                }
                $0.recordingUsecase.cancel = {
                    await cancellation.call()
                }
            }
        )

        // when, then
        await store.send(.alert(.presented(.cancelConfirmed))) {
            $0.alert = nil
        }
        await store.receive(\.recordingPanel.parent.discardConfirmed) {
            $0.recordingPanel.phase = .finished
        }
        await store.receive(\.recordingPanel.response.recordingDiscarding)
        await store.receive(\.recordingPanel.delegate.recordingDiscarded)
        await store.finish()
        #expect(await cancellation.callCount == 1)
        #expect(dismissal.callCount == 1)
    }

    @Test("녹음 저장을 확정하면 화면 입력으로 대화를 저장한 뒤 화면을 닫는다")
    func confirmedSavePersistsConversationBeforeDismissal() async {
        // given
        let persistence = ConversationSpy()
        let dismissal = DismissSpy()
        var state: RecordScreen.Root.Feature.State = .init(
            recordingPanel: .init(
                phase: .paused,
                currentTime: 3,
                pins: [1]
            )
        )
        state.conversationInfo.title = "  English Conversation  "
        state.conversationInfo.topic = "Travel"
        state.conversationInfo.parties = ["Marco"]
        state.alert = .confirmSave
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.date.now = .init(timeIntervalSince1970: 0)
                $0.dismiss = DismissEffect {
                    dismissal.call()
                }
                $0.recordingUsecase.finish = {
                    await persistence.save($0)
                }
            }
        )

        // when, then
        await store.send(.alert(.presented(.saveConfirmed))) {
            $0.alert = nil
        }
        await store.receive(\.recordingPanel.parent.saveConfirmed) {
            $0.recordingPanel.phase = .saving
        }
        await store.receive(\.recordingPanel.response.recordingSaving)
        await store.receive(\.recordingPanel.response.recordingSaved) {
            $0.recordingPanel.phase = .finished
        }
        await store.receive(\.recordingPanel.delegate.recordingSaved)
        await store.finish()

        let conversation = await persistence.conversation
        #expect(conversation?.title == "English Conversation")
        #expect(conversation?.topic == "Travel")
        #expect(conversation?.parties.map(\.name) == ["Marco"])
        #expect(conversation?.pins == [1])
        #expect(dismissal.callCount == 1)
    }

    @Test("RecordingPanel의 실패를 오류 Alert로 표시한다")
    func recordingFailureShowsAlert() async {
        // given
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.Root.Feature() }
        )

        // when, then
        await store.send(.recordingPanel(.delegate(.recordingFailed(.prepareFailed)))) {
            $0.alert = .prepareFailed
        }
        await store.send(.recordingPanel(.delegate(.recordingFailed(.saveFailed)))) {
            $0.alert = .saveFailed
        }
    }

}

private actor CallSpy {
    private(set) var callCount = 0

    func call() {
        callCount += 1
    }
}

@MainActor
private final class DismissSpy {
    private(set) var callCount = 0

    func call() {
        callCount += 1
    }
}

private actor ConversationSpy {
    private(set) var conversation: Conversation?

    func save(_ conversation: Conversation) {
        self.conversation = conversation
    }
}
