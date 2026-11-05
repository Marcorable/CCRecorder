
import Foundation
import AVFAudio
import Testing

import Domain
import ComposableArchitecture

@testable import Presentation

@Suite("대화 상세 재생 패널")
@MainActor
struct ConversationDetailScreenPlaybackPanelTests {}

extension ConversationDetailScreenPlaybackPanelTests {

    @Test("인터럽션이 시작되면 일시 정지하고 사용자가 다시 재생한다")
    func pausesAndAllowsManualReplayAfterInterruption() async {
        // given
        let clock = TestClock<Duration>()
        let events = AudioSessionEventSource()
        let preparation = PreparationSpy()
        let playback = PlaybackSpy()
        let store = TestStore(
            initialState: ConversationDetailScreen.PlaybackPanel.Feature.State(),
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            },
            withDependencies: {
                $0.continuousClock = clock
                $0.audioSession.activate = { try preparation.activateSession() }
                $0.audioSession.events = { events.stream }
                $0.playingRecordUsecase = .init(
                    isPrepared: { true },
                    isPlaying: { await playback.readIsPlaying() },
                    currentTime: { 3 },
                    duration: { 10 },
                    rate: { 1 },
                    prepare: { _ in preparation.record(.preparePlayer) },
                    play: { await playback.play() },
                    pause: { await playback.pause() },
                    finish: { await playback.finish() },
                    seek: { _ in },
                    changeRate: { _ in }
                )
            }
        )

        // when, then
        await store.send(.parent(.conversationLoaded(
            fileName: "recording.m4a",
            pins: []
        )))
        await store.receive(\.response.audioSessionUpdates)
        await store.receive(\.response.prepared)
        await store.receive(\.response.playbackUpdates)
        await store.receive(\.response.updated) {
            $0.isPrepared = true
            $0.isPlaying = true
            $0.currentTime = 3
            $0.duration = 10
        }
        #expect(preparation.steps == [.activateSession, .preparePlayer])

        events.send(.interruptionBegan)
        await store.receive(\.response.audioSessionEvent) {
            $0.isPlaying = false
        }
        await store.receive(\.delegate.interrupted)
        await playback.waitUntilPaused()
        let updatesBeforeClockAdvance = await playback.isPlayingReadCount
        await clock.advance(by: .seconds(1))
        #expect(await playback.isPlayingReadCount == updatesBeforeClockAdvance)

        await store.send(.view(.playButtonTapped))
        await store.receive(\.response.playbackStarted)
        await store.receive(\.response.playbackUpdates)
        await store.receive(\.response.updated) {
            $0.isPlaying = true
        }
        #expect(await playback.playCallCount == 1)
        #expect(preparation.steps == [
            .activateSession,
            .preparePlayer,
            .activateSession
        ])

        await store.send(.parent(.conversationDetailDisappeared)) {
            $0.isPrepared = false
            $0.isPlaying = false
            $0.currentTime = .zero
            $0.duration = .zero
            $0.isTerminated = true
        }
        await store.finish()
        #expect(await playback.finishCallCount == 1)
    }

    @Test("재생 세션 활성화에 실패하면 일시 정지하고 인터럽션을 다시 알린다")
    func activationFailureKeepsPausedAndReportsInterruption() async {
        // given
        let preparation = PreparationSpy()
        preparation.failActivation()
        let playback = PlaybackSpy()
        var state = ConversationDetailScreen.PlaybackPanel.Feature.State()
        state.isPrepared = true
        let store = TestStore(
            initialState: state,
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            },
            withDependencies: {
                $0.audioSession.activate = { try preparation.activateSession() }
                $0.playingRecordUsecase.play = { await playback.play() }
            }
        )

        // when, then
        await store.send(.view(.playButtonTapped))
        await store.receive(\.response.playbackStarted)
        await store.receive(\.delegate.interrupted)
        #expect(await playback.playCallCount == 0)
        #expect(preparation.steps == [.activateSession])
    }

    @Test("일시 정지 중 탐색과 배속 변경을 상태에 반영한다")
    func controlsUpdatePausedState() async {
        // given
        let playback = PlaybackSpy()
        var state = ConversationDetailScreen.PlaybackPanel.Feature.State()
        state.isPrepared = true
        state.isPlaying = true
        state.currentTime = 3
        state.duration = 20
        let store = TestStore(
            initialState: state,
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            },
            withDependencies: {
                $0.playingRecordUsecase = .init(
                    isPrepared: { true },
                    isPlaying: { await playback.readIsPlaying() },
                    currentTime: { await playback.readCurrentTime() },
                    duration: { 20 },
                    rate: { await playback.readRate() },
                    prepare: { _ in },
                    play: { await playback.play() },
                    pause: { await playback.pause() },
                    finish: { await playback.finish() },
                    seek: { await playback.seek(to: $0) },
                    changeRate: { await playback.changeRate(to: $0) }
                )
            }
        )

        await store.send(.view(.pauseButtonTapped)) {
            $0.isPlaying = false
        }
        await playback.waitUntilPaused()

        // when, then
        await store.send(.view(.skipForwardTapped)) {
            $0.currentTime = 8
        }
        await store.receive(\.response.seekStarted)
        await store.receive(\.response.seekCompleted)
        await store.send(.view(.skipForwardTapped)) {
            $0.currentTime = 13
        }
        await store.receive(\.response.seekStarted)
        await store.receive(\.response.seekCompleted)
        await store.send(.view(.speedChanged(.oneAndHalf))) {
            $0.speed = .oneAndHalf
        }
        await store.receive(\.response.rateChangeStarted)
        await store.receive(\.response.rateChangeCompleted)
        #expect(await playback.soughtTimes == [8, 13])
        #expect(await playback.readRate() == 1.5)
    }

    @Test("플레이어 배속 응답을 지원하는 Speed로 변환한다")
    func playerRateResponseUpdatesSpeed() async {
        // given
        let store = TestStore(
            initialState: ConversationDetailScreen.PlaybackPanel.Feature.State(),
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            }
        )

        // when, then
        await store.send(.response(.rateChangeCompleted(1.25))) {
            $0.speed = .oneAndOneQuarter
        }
        await store.send(.response(.rateChangeCompleted(1.1))) {
            $0.speed = .default
        }
    }

    @Test("일시 정지 중 인터럽션은 알럿을 요청하지 않는다")
    func pausedInterruptionDoesNotNotify() async {
        // given
        let playback = PlaybackSpy()
        var state = ConversationDetailScreen.PlaybackPanel.Feature.State()
        state.isPrepared = true
        let store = TestStore(
            initialState: state,
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            },
            withDependencies: {
                $0.playingRecordUsecase.pause = { await playback.pause() }
            }
        )

        // when
        await store.send(.response(.audioSessionEvent(.interruptionBegan)))
        await playback.waitUntilPaused()

        // then
        await store.finish()
    }

    @Test("오디오 장치 연결이 해제되면 재생을 일시 정지한다")
    func routeDisconnectionPausesPlayback() async {
        // given
        let playback = PlaybackSpy()
        var state = ConversationDetailScreen.PlaybackPanel.Feature.State()
        state.isPrepared = true
        state.isPlaying = true
        let store = TestStore(
            initialState: state,
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            },
            withDependencies: {
                $0.playingRecordUsecase.pause = { await playback.pause() }
            }
        )

        // when, then
        await store.send(.response(.audioSessionEvent(.routeDisconnected))) {
            $0.isPlaying = false
        }
        await store.receive(\.delegate.interrupted)
        await playback.waitUntilPaused()
        await store.finish()
    }

    @Test("상세 화면이 종료된 뒤 도착한 재생 응답은 상태를 되살리지 않는다")
    func latePlaybackResponseIsIgnoredAfterDisappearance() async {
        // given
        let playback = PlaybackSpy()
        var state = ConversationDetailScreen.PlaybackPanel.Feature.State()
        state.isPrepared = true
        state.isPlaying = true
        state.currentTime = 3
        state.duration = 10
        let store = TestStore(
            initialState: state,
            reducer: {
                ConversationDetailScreen.PlaybackPanel.Feature()
            },
            withDependencies: {
                $0.playingRecordUsecase.finish = { await playback.finish() }
            }
        )

        await store.send(.parent(.conversationDetailDisappeared)) {
            $0.isPrepared = false
            $0.isPlaying = false
            $0.currentTime = .zero
            $0.duration = .zero
            $0.isTerminated = true
        }
        await store.finish()

        // when, then
        await store.send(.response(.prepared(.success(()))))
        await store.send(.response(.updated(
            isPrepared: true,
            isPlaying: true,
            currentTime: 5,
            duration: 10,
            rate: 1.5
        )))
        #expect(await playback.finishCallCount == 1)
    }

    @Test("AVAudioSession 알림을 인터럽션과 장치 연결 해제 이벤트로 변환한다")
    func convertsAudioSessionNotificationsToEvents() {
        let began = Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [
                AVAudioSessionInterruptionTypeKey:
                    AVAudioSession.InterruptionType.began.rawValue
            ]
        )
        let ended = Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [
                AVAudioSessionInterruptionTypeKey:
                    AVAudioSession.InterruptionType.ended.rawValue
            ]
        )
        let disconnected = Notification(
            name: AVAudioSession.routeChangeNotification,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey:
                    AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
            ]
        )
        let connected = Notification(
            name: AVAudioSession.routeChangeNotification,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey:
                    AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
            ]
        )

        #expect(AudioSessionClient.Event(notification: began) == .interruptionBegan)
        #expect(AudioSessionClient.Event(notification: ended) == nil)
        #expect(AudioSessionClient.Event(notification: disconnected) == .routeDisconnected)
        #expect(AudioSessionClient.Event(notification: connected) == nil)
    }

}

private extension ConversationDetailScreenPlaybackPanelTests {

    final class AudioSessionEventSource: @unchecked Sendable {
        let stream: AsyncStream<AudioSessionClient.Event>
        private let continuation: AsyncStream<AudioSessionClient.Event>.Continuation

        init() {
            (stream, continuation) = AsyncStream.makeStream()
        }

        func send(_ event: AudioSessionClient.Event) {
            continuation.yield(event)
        }
    }

    final class PreparationSpy: @unchecked Sendable {
        enum Error: Swift.Error {
            case activationFailed
        }

        enum Step: Equatable {
            case activateSession
            case preparePlayer
        }

        private let lock = NSLock()
        private var recordedSteps: [Step] = []
        private var shouldFailActivation = false

        var steps: [Step] {
            lock.withLock { recordedSteps }
        }

        func record(_ step: Step) {
            lock.withLock { recordedSteps.append(step) }
        }

        func activateSession() throws {
            let shouldFail = lock.withLock {
                recordedSteps.append(.activateSession)
                return shouldFailActivation
            }
            if shouldFail {
                throw Error.activationFailed
            }
        }

        func failActivation() {
            lock.withLock { shouldFailActivation = true }
        }
    }

    actor PlaybackSpy {
        private(set) var isPlaying = true
        private(set) var isPlayingReadCount = 0
        private(set) var playCallCount = 0
        private(set) var finishCallCount = 0
        private(set) var soughtTimes: [TimeInterval] = []
        private var pauseContinuations: [CheckedContinuation<Void, Never>] = []
        private var pauseCallCount = 0
        private var currentTime: TimeInterval = 3
        private var rate: Float = 1

        func readIsPlaying() -> Bool {
            isPlayingReadCount += 1
            return isPlaying
        }

        func play() {
            playCallCount += 1
            isPlaying = true
        }

        func readCurrentTime() -> TimeInterval {
            currentTime
        }

        func readRate() -> Float {
            rate
        }

        func pause() {
            pauseCallCount += 1
            isPlaying = false
            pauseContinuations.forEach({ $0.resume() })
            pauseContinuations = []
        }

        func waitUntilPaused() async {
            guard pauseCallCount == 0 else {
                return
            }
            await withCheckedContinuation { continuation in
                pauseContinuations.append(continuation)
            }
        }

        func finish() {
            finishCallCount += 1
            isPlaying = false
        }

        func seek(to time: TimeInterval) {
            soughtTimes.append(time)
            currentTime = time
        }

        func changeRate(to rate: Float) {
            self.rate = rate
        }
    }

}
