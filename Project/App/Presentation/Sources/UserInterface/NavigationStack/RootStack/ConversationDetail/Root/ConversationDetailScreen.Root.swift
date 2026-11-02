
import SwiftUI

import Domain
import ComposableArchitecture

enum ConversationDetailScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            Group {
                if let conversation = store.conversation {
                    VStack {
                        Editor(store: store)
                        NoteList(
                            notes: store.notes,
                            select: { store.send(.view(.noteSelected($0))) },
                            delete: { store.send(.view(.notesDeleted($0))) }
                        )
                        PlaybackPanel(
                            store: store,
                            pins: conversation.pins
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
            .alert(
                "녹음 파일을 재생할 수 없습니다",
                isPresented: Binding(
                    get: { store.playbackFailure != nil },
                    set: { _ in store.send(.view(.alertDismissed)) }
                )
            ) {
                Button("확인", role: .cancel) {}
            }
        }

    }

}
