
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen {

    struct Editor: View {
        let store: StoreOf<Root.Feature>

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
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isEditing {
                        TextField(
                            "Title",
                            text: Binding(
                                get: { store.conversation?.title ?? "" },
                                set: { store.send(.view(.titleChanged($0))) }
                            ),
                            prompt: Text(
                                store.conversation?.createdDate.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                ) ?? ""
                            )
                        )
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .infoTitle)
                    } else {
                        Text(store.conversation?.title ?? "")
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
