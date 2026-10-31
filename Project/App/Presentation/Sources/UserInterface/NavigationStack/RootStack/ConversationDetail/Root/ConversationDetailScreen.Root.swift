
import SwiftUI

import Domain
import ComposableArchitecture

enum ConversationDetailScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            Group {
                if let conversation = store.conversation {
                    content(conversation: conversation)
                } else if store.conversationLoadFailed {
                    ContentUnavailableView(
                        "대화를 불러올 수 없습니다",
                        systemImage: "exclamationmark.triangle"
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(store.conversation?.title ?? "Conversation")
            .navigationBarTitleDisplayMode(.inline)
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

        private func content(conversation: Conversation) -> some View {
            Form {
                Section("대화 정보") {
                    TextField(
                        "제목",
                        text: Binding(
                            get: { store.conversation?.title ?? "" },
                            set: { store.send(.view(.titleChanged($0))) }
                        )
                    )
                    TextField(
                        "주제",
                        text: Binding(
                            get: { store.conversation?.topic ?? "" },
                            set: { store.send(.view(.topicChanged($0))) }
                        )
                    )
                    HStack {
                        TextField(
                            "참여인원",
                            text: Binding(
                                get: { store.partyInput },
                                set: { store.send(.view(.partyInputChanged($0))) }
                            )
                        )
                        Button("추가") { store.send(.view(.partyAdded)) }
                    }
                    ForEach(conversation.parties) { party in
                        LabeledContent(party.name) {
                            Button("삭제") { store.send(.view(.partyRemoved(party.id))) }
                        }
                    }
                }
                Section("노트") {
                    HStack {
                        TextField(
                            "영어 또는 한글 메모",
                            text: Binding(
                                get: { store.noteInput },
                                set: { store.send(.view(.noteInputChanged($0))) }
                            )
                        )
                        Button("추가") { store.send(.view(.noteAdded)) }
                    }
                    ForEach(store.notes) { note in
                        Button(note.original.isEmpty ? note.translation : note.original) {
                            store.send(.view(.noteSelected(note.id)))
                        }
                    }
                    .onDelete { store.send(.view(.notesDeleted($0))) }
                }
                Section("재생") {
                    Slider(
                        value: Binding(
                            get: { store.playback.currentTime },
                            set: { store.send(.view(.seekChanged($0))) }
                        ),
                        in: .zero...max(store.playback.duration, 0.01)
                    )
                    HStack {
                        Text(store.playback.currentTime, format: .playbackTime)
                        Spacer()
                        Button("-\(store.skipInterval.rawValue)") {
                            store.send(.view(.skipBackwardTapped))
                        }
                        Button(store.playback.isPlaying ? "일시정지" : "재생") {
                            store.send(
                                store.playback.isPlaying
                                    ? .view(.pauseButtonTapped)
                                    : .view(.playButtonTapped)
                            )
                        }
                        Button("+\(store.skipInterval.rawValue)") {
                            store.send(.view(.skipForwardTapped))
                        }
                        Button("다음 핀") {
                            store.send(.view(.nextPinTapped))
                        }
                        .disabled(
                            !conversation.pins.contains(
                                where: { $0 > store.playback.currentTime }
                            )
                        )
                        Spacer()
                        Text(store.playback.duration, format: .playbackTime)
                    }
                    Picker(
                        "재생 속도",
                        selection: Binding(
                            get: { store.playback.rate },
                            set: { store.send(.view(.rateChanged($0))) }
                        )
                    ) {
                        Text("0.5x").tag(Float(0.5))
                        Text("1.0x").tag(Float(1.0))
                        Text("1.5x").tag(Float(1.5))
                        Text("2.0x").tag(Float(2.0))
                    }
                }
            }
        }
    }

}
