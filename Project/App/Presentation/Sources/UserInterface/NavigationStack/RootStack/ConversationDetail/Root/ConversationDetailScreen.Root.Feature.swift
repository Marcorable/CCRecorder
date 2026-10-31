
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
                    case .noteDetail(.dismiss):
                        guard let conversation = state.conversation else {
                            return .none
                        }
                        return .run { send in
                            await send(.response(.notesLoaded(
                                await managingConversationUsecase.notes(conversation)
                            )))
                        }

                    case .view(let action):
                        return reduce(into: &state, action: action)

                    case .response(let action):
                        return reduce(into: &state, action: action)

                    case .noteDetail:
                        return .none
                }
            }
            .ifLet(\.$noteDetail, action: \.noteDetail) {
                NoteDetailScreen.Root.Feature()
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
                let id = state.conversationID
                return .run { send in
                    await send(.response(.conversationLoaded(
                        await managingConversationUsecase.conversation(id)
                    )))
                }
                .cancellable(
                    id: CancelID.loadConversation,
                    cancelInFlight: true
                )

            case .disappeared:
                return .merge(
                    .cancel(id: CancelID.loadConversation),
                    .cancel(id: CancelID.playback),
                    .run { _ in await playingRecordUsecase.finish() }
                )

            case .titleChanged(let title):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.title = title
                state.conversation = conversation
                return update(conversation)

            case .topicChanged(let topic):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.topic = topic
                state.conversation = conversation
                return update(conversation)

            case .editingToggled:
                state.isEditing.toggle()
                return .none

            case .partyInputChanged(let party):
                state.partyInput = party
                return .none

            case .partyAdded:
                guard !state.partyInput.isEmpty, var conversation = state.conversation else {
                    return .none
                }
                conversation.parties.append(.init(name: state.partyInput))
                state.conversation = conversation
                state.partyInput = ""
                return update(conversation)

            case .partyRemoved(let id):
                guard var conversation = state.conversation else {
                    return .none
                }
                conversation.parties.removeAll(where: { $0.id == id })
                state.conversation = conversation
                return update(conversation)

            case .noteInputChanged(let input):
                state.noteInput = input
                return .none

            case .noteAdded:
                let input = state.noteInput
                guard let conversation = state.conversation else {
                    return .none
                }
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
                guard let conversation = state.conversation else {
                    return .none
                }
                return .run { send in
                    await send(.response(.notesDeleted(
                        TaskResult {
                            try await managingConversationUsecase.deleteNotes(ids, conversation)
                        }
                    )))
                }

            case .noteSelected(let id):
                state.noteDetail = .init(noteID: id)
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
                guard let pin = state.conversation?.pins.sorted().first(
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
            case .conversationLoaded(.success(let conversation)):
                state.conversation = conversation
                state.conversationLoadFailed = conversation == nil
                guard let conversation else {
                    return .none
                }
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
                    .cancellable(id: CancelID.playback, cancelInFlight: true)
                )

            case .conversationLoaded(.failure):
                state.conversationLoadFailed = true
                return .none

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
        case loadConversation
        case playback
        case update
    }

}

extension ConversationDetailScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        let conversationID: Conversation.ID
        var conversation: Conversation?
        var conversationLoadFailed = false
        var notes: [Note] = []
        var noteInput: String = ""
        var partyInput: String = ""
        var isEditing: Bool = false
        var playback: Playback = .init()
        var playbackFailure: PlaybackFailure?
        @Presents var noteDetail: NoteDetailScreen.Root.Feature.State?
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

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case response(Response)
        case noteDetail(PresentationAction<NoteDetailScreen.Root.Feature.Action>)

        @CasePathable
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
            case noteSelected(Note.ID)
            case playButtonTapped
            case pauseButtonTapped
            case seekChanged(TimeInterval)
            case skipBackwardTapped
            case skipForwardTapped
            case nextPinTapped
            case rateChanged(Float)
            case alertDismissed
        }

        @CasePathable
        enum Response {
            case conversationLoaded(Result<Conversation?, DomainError>)
            case notesLoaded(Result<[Note], DomainError>)
            case playbackPrepared(TaskResult<Void>)
            case playbackUpdated(State.Playback)
            case noteAdded(TaskResult<Conversation>)
            case notesDeleted(TaskResult<Conversation>)
        }
    }

}
