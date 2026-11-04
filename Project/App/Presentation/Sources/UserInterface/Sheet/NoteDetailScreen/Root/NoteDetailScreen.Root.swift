import SwiftUI

import ComposableArchitecture

enum NoteDetailScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            let presentationDetents: Set<PresentationDetent> = switch store.isVocabulary {
                case true:     [.medium]
                case false:    [.medium, .large]
                case nil:      [.large]
            }

            NavigationStack {
                Group {
                    if let isVocabulary = store.isVocabulary {
                        VStack(alignment: .leading) {
                            if isVocabulary {
                                VocabularyContent(
                                    original: $store.original,
                                    translation: $store.translation
                                )
                            } else {
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
                                isVocabulary: isVocabulary,
                                saveAction: { store.send(.view(.saveButtonTapped)) }
                            )
                        }
                    } else if store.noteLoadFailed {
                        ContentUnavailableView(
                            "노트를 불러올 수 없습니다",
                            systemImage: "exclamationmark.triangle"
                        )
                    } else {
                        ProgressView()
                    }
                }
            }
            .presentationDetents(presentationDetents)
            .task { await store.send(.view(.appeared)).finish() }
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
                    Image(
                        systemName: isVocabulary
                            ? "textformat.abc"
                            : "text.bubble.fill"
                    )
                        .foregroundStyle(Color(asset: Asset.Logo.Prominent.red))
                    Text(isVocabulary ? "Vocabulary" : "Sentence")
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
    }

}

#Preview("Vocabulary") {
    let noteID = UUID()
    NoteDetailScreen.Root(
        store: .init(
            initialState: .init(noteID: noteID),
            reducer: {
                NoteDetailScreen.Root.Feature()
            },
            withDependencies: {
                $0.managingNoteUsecase.note = { _ in
                    .success(
                        .init(
                            id: noteID,
                            createdDate: .init(),
                            original: "conversation",
                            translation: "대화",
                            category: .vocabulary
                        )
                    )
                }
            }
        )
    )
}

#Preview("Sentence") {
    let noteID = UUID()
    NoteDetailScreen.Root(
        store: .init(
            initialState: .init(noteID: noteID),
            reducer: {
                NoteDetailScreen.Root.Feature()
            },
            withDependencies: {
                $0.managingNoteUsecase.note = { _ in
                    .success(
                        .init(
                            id: noteID,
                            createdDate: .init(),
                            original: "This is a sentence.",
                            translation: "문장입니다.",
                            category: .sentence
                        )
                    )
                }
            }
        )
    )
}
