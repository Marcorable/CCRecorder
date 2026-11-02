
import Foundation
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("녹음 화면 Feature")
@MainActor
struct RecordScreenFeatureTests {}

extension RecordScreenFeatureTests {

    @Test("마이크 권한이 거부되면 권한 안내를 표시한다")
    func deniedPermissionShowsAlert() async {
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
        await store.receive(\.response.audioSessionAuthorization) {
            $0.phase = .idle
            $0.alert = .permissionDenied
        }
    }

    @Test("녹음 준비에 성공하면 대기 상태가 된다")
    func preparationMovesToIdle() async {
        // given
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .authorized }
                $0.audioSession.activate = {}
                $0.recordingUsecase.prepare = {}
                $0.recordingUsecase.currentTime = { 1 }
            }
        )

        // when, then
        await store.send(.view(.task))
        await store.receive(\.response.audioSessionAuthorization)
        await store.receive(\.response.prepared) {
            $0.phase = .idle
            $0.currentTime = 1
        }
    }

    @Test("녹음 준비에 실패하면 오류를 표시한다")
    func preparationFailureShowsAlert() async {
        // given
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: .init(),
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.audioSession.authorizationStatus = { .authorized }
                $0.audioSession.activate = {}
                $0.recordingUsecase.prepare = {
                    throw DomainError.recordingUsecase(.prepareFailed)
                }
            }
        )

        // when, then
        await store.send(.view(.task))
        await store.receive(\.response.audioSessionAuthorization)
        await store.receive(\.response.recordingFailed) {
            $0.phase = .idle
            $0.alert = .prepareFailed
        }
    }

    @Test("저장하지 않고 화면이 닫히면 녹음을 취소한다")
    func disappearanceCancelsRecording() async {
        // given
        let spy = CallSpy()
        var state: RecordScreen.Root.Feature.State = .init()
        state.phase = .recording
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.recordingUsecase.cancel = {
                    await spy.call()
                }
            }
        )

        // when
        await store.send(.view(.disappeared)) {
            $0.isFinished = true
        }

        // then
        #expect(await spy.callCount == 1)
    }

    @Test("화면이 닫힌 뒤 도착한 준비 응답은 상태를 되살리지 않는다")
    func latePreparationResponseIsIgnored() async {
        // given
        var state: RecordScreen.Root.Feature.State = .init()
        state.isFinished = true
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() }
        )

        // when, then
        await store.send(.response(.prepared(3)))
    }

    @Test("녹음 저장에 실패하면 다시 시도할 수 있는 상태가 된다")
    func saveFailureRestoresIdleState() async {
        // given
        var state: RecordScreen.Root.Feature.State = .init()
        state.phase = .saving
        let store: TestStoreOf<RecordScreen.Root.Feature> = .init(
            initialState: state,
            reducer: { RecordScreen.Root.Feature() }
        )

        // when, then
        await store.send(.response(.recordingFailed(.saveFailed))) {
            $0.phase = .idle
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
