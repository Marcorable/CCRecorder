
import SwiftUI

import Domain
import ComposableArchitecture

enum ConversationDetailScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            Group {
                if store.conversation != nil {
                    VStack {
                        Editor(
                            store: store,
                            notesStore: store.scope(
                                state: \.notes,
                                action: \.notes
                            )
                        )
                        NoteList(
                            store: store.scope(
                                state: \.notes,
                                action: \.notes
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
                    .presentationDetents(
                        store.note?.category.presentationDetents ?? [.large]
                    )
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }

    }

}
