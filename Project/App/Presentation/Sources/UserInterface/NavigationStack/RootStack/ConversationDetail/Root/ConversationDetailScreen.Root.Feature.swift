
import Foundation

import Domain
import ComposableArchitecture

extension ConversationDetailScreen.Root {

    @Reducer
    struct Feature {
        @Dependency(\.managingConversationUsecase) private var managingConversationUsecase
        @Dependency(\.playingRecordUsecase) private var playingRecordUsecase

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)
                }
            }
        }
    }

}

extension ConversationDetailScreen.Root.Feature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .appeared:
                let conversation = state.conversation
                return .merge(
                    .run { send in
                        await send(.response(.notesLoaded(
                            await managingConversationUsecase.notes(conversation)
                        )))
                    },
                    .run { send in
                        await send(.response(.playbackPrepared(
                            TaskResult {
                                try await playingRecordUsecase.prepare(conversation.recordFileName)
                            }
                        )))
                    }
                )

            case .disappeared:
                return .merge(
                    .cancel(id: CancelID.playback),
                    .run { _ in await playingRecordUsecase.finish() }
                )

            case .titleChanged(let title):
                state.conversation.title = title
                return update(state.conversation)

            case .topicChanged(let topic):
                state.conversation.topic = topic
                return update(state.conversation)

            case .editingToggled:
                state.isEditing.toggle()
                return .none

            case .partyInputChanged(let party):
                state.partyInput = party
                return .none

            case .partyAdded:
                guard !state.partyInput.isEmpty else {
                    return .none
                }
                state.conversation.parties.append(.init(name: state.partyInput))
                state.partyInput = ""
                return update(state.conversation)

            case .partyRemoved(let id):
                state.conversation.parties.removeAll(where: { $0.id == id })
                return update(state.conversation)

            case .noteInputChanged(let input):
                state.noteInput = input
                return .none

            case .noteAdded:
                let input = state.noteInput
                let conversation = state.conversation
                state.noteInput = ""
                return .run { send in
                    await send(.response(.noteAdded(
                        TaskResult {
                            try await managingConversationUsecase.addNote(input, conversation)
                        }
                    )))
                }

            case .notesDeleted(let offsets):
                let ids = offsets.map({ state.notes[$0].id })
                let conversation = state.conversation
                return .run { send in
                    await send(.response(.notesDeleted(
                        TaskResult {
                            try await managingConversationUsecase.deleteNotes(ids, conversation)
                        }
                    )))
                }

            case .noteSelected(let note):
                state.selectedNote = note
                return .none

            case .noteDismissed:
                state.selectedNote = nil
                return .none

            case .playButtonTapped:
                return .run { _ in await playingRecordUsecase.play() }

            case .pauseButtonTapped:
                return .run { _ in await playingRecordUsecase.pause() }

            case .seekChanged(let time):
                return .run { _ in await playingRecordUsecase.seek(time) }

            case .skipBackwardTapped:
                let time = state.playback.currentTime - state.skipInterval.timeInterval
                return .run { _ in await playingRecordUsecase.seek(time) }

            case .skipForwardTapped:
                let time = state.playback.currentTime + state.skipInterval.timeInterval
                return .run { _ in await playingRecordUsecase.seek(time) }

            case .nextPinTapped:
                guard let pin = state.conversation.pins.sorted().first(
                    where: { $0 > state.playback.currentTime }
                ) else {
                    return .none
                }
                return .run { _ in await playingRecordUsecase.seek(pin) }

            case .rateChanged(let rate):
                return .run { _ in await playingRecordUsecase.changeRate(rate) }

            case .alertDismissed:
                state.playbackFailure = nil
                return .none
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .notesLoaded(.success(let notes)):
                state.notes = notes
                return .none

            case .notesLoaded(.failure):
                return .none

            case .playbackPrepared(.success):
                return .run { send in
                    while !Task.isCancelled {
                        await send(.response(.playbackUpdated(
                            .init(
                                isPlaying: await playingRecordUsecase.isPlaying(),
                                currentTime: await playingRecordUsecase.currentTime(),
                                duration: await playingRecordUsecase.duration(),
                                rate: await playingRecordUsecase.rate()
                            )
                        )))
                        try await Task.sleep(for: .milliseconds(100))
                    }
                }
                .cancellable(id: CancelID.playback, cancelInFlight: true)

            case .playbackPrepared(.failure(let error)):
                switch error as? DomainError {
                    case .playingRecordUsecase(.fileNotFound):
                        state.playbackFailure = .fileNotFound

                    case .playingRecordUsecase(.prepareFailed), .none, .some:
                        state.playbackFailure = .prepareFailed
                }
                return .none

            case .playbackUpdated(let playback):
                state.playback = playback
                return .none

            case .noteAdded(.success(let conversation)),
                 .notesDeleted(.success(let conversation)):
                state.conversation = conversation
                return .run { send in
                    await send(.response(.notesLoaded(
                        await managingConversationUsecase.notes(conversation)
                    )))
                }

            case .noteAdded(.failure), .notesDeleted(.failure):
                return .none
        }
    }

    private func update(_ conversation: Conversation) -> Effect<Action> {
        .run { _ in
            try await Task.sleep(for: .seconds(1))
            try await managingConversationUsecase.update(conversation)
        }
        .cancellable(id: CancelID.update, cancelInFlight: true)
    }

    private enum CancelID {
        case playback
        case update
    }

}

extension ConversationDetailScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        var conversation: Conversation
        var notes: [Note] = []
        var noteInput: String = ""
        var partyInput: String = ""
        var isEditing: Bool = false
        var playback: Playback = .init()
        var playbackFailure: PlaybackFailure?
        var selectedNote: Note?
        @Shared(.appStorage(Key.skipInterval.rawValue)) var skipInterval: SkipInterval = .five

        struct Playback: Equatable {
            var isPlaying: Bool = false
            var currentTime: TimeInterval = .zero
            var duration: TimeInterval = .zero
            var rate: Float = 1
        }

        enum PlaybackFailure: Equatable {
            case fileNotFound
            case prepareFailed
        }
    }

    enum Action: ViewAction {
        case view(View)
        case response(Response)

        enum View {
            case appeared
            case disappeared
            case titleChanged(String)
            case topicChanged(String)
            case editingToggled
            case partyInputChanged(String)
            case partyAdded
            case partyRemoved(Party.ID)
            case noteInputChanged(String)
            case noteAdded
            case notesDeleted(IndexSet)
            case noteSelected(Note)
            case noteDismissed
            case playButtonTapped
            case pauseButtonTapped
            case seekChanged(TimeInterval)
            case skipBackwardTapped
            case skipForwardTapped
            case nextPinTapped
            case rateChanged(Float)
            case alertDismissed
        }

        enum Response {
            case notesLoaded(Result<[Note], DomainError>)
            case playbackPrepared(TaskResult<Void>)
            case playbackUpdated(State.Playback)
            case noteAdded(TaskResult<Conversation>)
            case notesDeleted(TaskResult<Conversation>)
        }
    }

}
