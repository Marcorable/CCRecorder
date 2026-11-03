
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen {

    struct Editor: View {
        let store: StoreOf<Feature>

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
                NoteBoard(
                    rows: store.rows,
                    onTap: { store.send(.view(.noteSelected($0))) },
                    onDelete: { store.send(.view(.notesDeleted($0))) }
                )
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
                            prompt: Text(store.createdDateText)
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

extension ConversationDetailScreen.Editor {

    enum Field: Hashable {
        case infoTitle
        case infoTopic
        case infoParty
        case inputNote
    }

}
