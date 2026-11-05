
import SwiftUI

import ComposableArchitecture

enum ConversationDetailScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            Group {
                if store.editor.createdDate != nil {
                    VStack {
                        Editor(
                            store: store.scope(
                                state: \.editor,
                                action: \.editor
                            )
                        )
                        PlaybackPanel(
                            store: store.scope(
                                state: \.playbackPanel,
                                action: \.playbackPanel
                            )
                        )
                    }
                } else if store.conversationLoadFailed {
                    ContentUnavailableView(
                        "대화를 불러올 수 없습니다",
                        systemImage: "exclamationmark.triangle"
                    )
                } else {
                    ProgressView()
                }
            }
            .task { await store.send(.view(.appeared)).finish() }
            .onDisappear { store.send(.view(.disappeared)) }
            .sheet(
                item: $store.scope(
                    state: \.noteDetail,
                    action: \.noteDetail
                )
            ) { store in
                NoteDetailScreen.Root(store: store)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }

    }

}

#Preview("Loaded") {
    NavigationStack {
        ConversationDetailScreen.Root(
            store: .init(
                initialState: {
                    var state: ConversationDetailScreen.Root.Feature.State = .init(conversationID: .init())
                    state.editor = .init(
                        conversationID: state.conversationID,
                        title: "영어 회화",
                        createdDate: .init(timeIntervalSince1970: 1_735_689_600),
                        topic: "여행 계획",
                        parties: [
                            .init(
                                id: .init(),
                                name: "Marco"
                            ),
                            .init(
                                id: .init(),
                                name: "John"
                            )
                        ],
                        rows: [
                            .init(
                                id: .init(),
                                original: "How have you been?",
                                translation: "어떻게 지냈어요?",
                                isVocabulary: false
                            ),
                            .init(
                                id: .init(),
                                original: "Itinerary",
                                translation: "여행 일정",
                                isVocabulary: true
                            )
                        ]
                    )
                    state.playbackPanel = .init(
                        isPrepared: true,
                        currentTime: 82,
                        duration: 245,
                        speed: .oneAndOneQuarter,
                        pins: [30, 95, 180]
                    )
                    return state
                }(),
                reducer: { ConversationDetailScreen.Root.Feature() },
                withDependencies: {
                    $0.audioSession = .preview
                    $0.managingConversationUsecase = .preview
                    $0.navigator = .preview
                    $0.playingRecordUsecase = .preview
                }
            )
        )
    }
}
