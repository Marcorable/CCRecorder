
import UIKit
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen.Editor {

    struct InputBox: View {
        let store: StoreOf<Feature>
        let focusedField: FocusState<Field?>.Binding

        var body: some View {
            GroupBox {
                HStack {
                    TextField(
                        "Input Text",
                        text: Binding(
                            get: { store.noteInput },
                            set: { store.send(.view(.noteInputChanged($0))) }
                        ),
                        prompt: Text("영어 또는 한글 메모를 작성하세요")
                    )
                    .trailingAction(
                        of: !store.noteInput.isEmpty,
                        label: {
                            Image(systemName: "multiply.circle.fill")
                                .accessibilityLabel("입력 내용 지우기")
                        },
                        action: { store.send(.view(.noteInputChanged(""))) }
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused(focusedField, equals: .inputNote)
                    .onSubmit { store.send(.view(.noteAdded)) }
                    Button(
                        action: { store.send(.view(.noteAdded)) },
                        label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .padding(.leading)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(
                        action: {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        },
                        label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    )
                    Spacer()
                    Button("추가") {
                        store.send(.view(.noteAdded))
                    }
                }
            }
        }
    }

}
