import SwiftUI

import ComposableArchitecture

enum NoteDetailScreen {

    struct Root: View {
        @Bindable var store: StoreOf<Feature>

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading) {
                    switch store.note.category {
                        case .vocabulary:
                            VocabularyContent(
                                original: $store.original,
                                translation: $store.translation
                            )

                        case .sentence:
                            SentenceContent(
                                original: $store.original,
                                translation: $store.translation
                            )
                    }
                }
                .padding(.horizontal)
                .toolbar {
                    Toolbar(
                        isAbleToSave: store.isAbleToSave,
                        isVocabulary: store.note.category == .vocabulary,
                        saveAction: { store.send(.view(.saveButtonTapped)) }
                    )
                }
            }
            .alert($store.scope(state: \.$alert, action: \.alert))
        }
    }

}

extension NoteDetailScreen.Root {

    struct Toolbar: ToolbarContent {
        let isAbleToSave: Bool
        let isVocabulary: Bool
        let saveAction: () -> Void

        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: imageSystemName)
                        .foregroundStyle(Color(asset: Asset.Logo.Prominent.red))
                    Text(title)
                        .font(.headline)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    action: saveAction,
                    label: {
                        Text("저장")
                            .font(.headline)
                            .tint(Color(asset: Asset.Logo.Muted.green))
                    }
                )
                .disabled(!isAbleToSave)
                .opacity(isAbleToSave ? 1 : 0.3)
            }
        }

        private var title: String {
            isVocabulary ? "Vocabulary" : "Sentence"
        }

        private var imageSystemName: String {
            isVocabulary ? "textformat.abc" : "text.bubble.fill"
        }
    }

}

#if DEBUG
#Preview("Vocabulary") {
    NoteDetailScreen.Root(
        store: .init(
            initialState: .init(
                note: .init(
                    createdDate: .init(),
                    original: "conversation",
                    translation: "대화",
                    category: .vocabulary
                )
            ),
            reducer: {
                NoteDetailScreen.Root.Feature.preview
            }
        )
    )
}

#Preview("Sentence") {
    NoteDetailScreen.Root(
        store: .init(
            initialState: .init(
                note: .init(
                    createdDate: .init(),
                    original: "This is a sentence.",
                    translation: "문장입니다.",
                    category: .sentence
                )
            ),
            reducer: {
                NoteDetailScreen.Root.Feature.preview
            }
        )
    )
}
#endif
