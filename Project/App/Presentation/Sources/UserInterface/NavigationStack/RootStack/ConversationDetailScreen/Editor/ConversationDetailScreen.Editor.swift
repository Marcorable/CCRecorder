
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen {

    struct Editor: View {
        let store: StoreOf<Feature>

        enum Field: Hashable {
            case infoTitle
            case infoTopic
            case infoParty
            case inputNote
        }

        @FocusState private var focusedField: Field?

        var body: some View {
            VStack {
                if focusedField != .inputNote {
                    InformationBox(
                        store: store,
                        focusedField: $focusedField
                    )
                    .transition(.opacity)
                }
                InputBox(
                    store: store,
                    focusedField: $focusedField
                )
                .animation(.easeOut, value: focusedField)
                .disabled(store.isLoading)
                NoteBoard(
                    rows: store.rows,
                    onTap: { store.send(.view(.noteSelected($0))) },
                    onDelete: { store.send(.view(.notesDeleted($0))) }
                )
                .disabled(store.isLoading)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isEditing {
                        TextField(
                            "Title",
                            text: Binding(
                                get: { store.title },
                                set: { store.send(.view(.titleChanged($0))) }
                            ),
                            prompt: Text(
                                store.createdDate?.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                ) ?? ""
                            )
                        )
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .infoTitle)
                    } else {
                        Text(store.title)
                            .font(.headline)
                    }
                }
            }
        }
    }

}

#Preview("Loaded") {
    NavigationStack {
        ConversationDetailScreen.Editor(
            store: .init(
                initialState: .init(
                    conversationID: .init(),
                    title: "영어 회화",
                    createdDate: .init(timeIntervalSince1970: 1_735_689_600),
                    topic: "여행 계획",
                    parties: [
                        ConversationDetailScreen.Editor.Feature.State.Party(
                            id: .init(),
                            name: "Marco"
                        ),
                        ConversationDetailScreen.Editor.Feature.State.Party(
                            id: .init(),
                            name: "John"
                        )
                    ],
                    isEditing: true,
                    noteInput: "Where should we meet?",
                    rows: [
                        NoteBoard.Row.ViewModel(
                            id: .init(),
                            original: "How have you been?",
                            translation: "어떻게 지냈어요?",
                            isVocabulary: false
                        ),
                        NoteBoard.Row.ViewModel(
                            id: .init(),
                            original: "Itinerary",
                            translation: "여행 일정",
                            isVocabulary: true
                        )
                    ]
                ),
                reducer: { ConversationDetailScreen.Editor.Feature() },
                withDependencies: {
                    $0.managingConversationUsecase = .preview
                }
            )
        )
    }
}
