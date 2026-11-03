
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen.Editor {

    struct InformationBox: View {
        let store: StoreOf<Feature>
        let focusedField: FocusState<Field?>.Binding

        var body: some View {
            GroupBox {
                Button(
                    action: {
                        withAnimation {
                            _ = store.send(.view(.editingToggled))
                        }
                    },
                    label: {
                        HStack {
                            Text("Conversation Information")
                                .font(.headline)
                            Spacer()
                            if store.isEditing {
                                Text("완료")
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color(asset: Asset.Logo.Muted.green))
                                .rotationEffect(.degrees(store.isEditing ? 90 : 0))
                        }
                    }
                )
                if store.isEditing {
                    VStack {
                        HStack {
                            Text("주제")
                                .font(.body)
                                .fontWeight(.bold)
                            TextField(
                                "Topic",
                                text: Binding(
                                    get: { store.topic },
                                    set: { store.send(.view(.topicChanged($0))) }
                                ),
                                prompt: Text("주제를 입력하세요")
                            )
                            .textFieldStyle(.roundedBorder)
                        }
                        .focused(focusedField, equals: .infoTopic)
                        HStack {
                            Text("참여")
                                .font(.body)
                                .fontWeight(.bold)
                            TextField(
                                "Party",
                                text: Binding(
                                    get: { store.partyInput },
                                    set: { store.send(.view(.partyInputChanged($0))) }
                                ),
                                prompt: Text("참여인원을 추가하세요 (공백 분리)")
                            )
                            .textFieldStyle(.roundedBorder)
                            Button(
                                action: { store.send(.view(.partyAdded)) },
                                label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .padding(.leading)
                                }
                            )
                        }
                        .focused(focusedField, equals: .infoParty)
                        if !store.parties.isEmpty {
                            ScrollView(.horizontal, showsIndicators: true) {
                                HStack(alignment: .center) {
                                    Text("\(store.parties.count)명")
                                        .font(.body)
                                        .fontWeight(.bold)
                                    LazyHGrid(rows: [.init(.flexible())]) {
                                        ForEach(store.parties) { party in
                                            HStack(spacing: 6) {
                                                Text(party.name)
                                                Button(
                                                    action: {
                                                        store.send(.view(.partyRemoved(party.id)))
                                                    },
                                                    label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(
                                                                Color(asset: Asset.Logo.Prominent.red)
                                                            )
                                                    }
                                                )
                                            }
                                            .padding(6)
                                            .foregroundStyle(.primary)
                                            .background(
                                                Color(asset: Asset.Surface.Background.primary)
                                            )
                                            .clipShape(.rect(cornerRadius: 10))
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

}
