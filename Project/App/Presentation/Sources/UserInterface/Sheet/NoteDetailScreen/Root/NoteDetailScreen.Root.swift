import SwiftUI

import Domain
import ComposableArchitecture

enum NoteDetailScreen {

    struct Root: View {
        @State var store: StoreOf<Feature>

        var body: some View {
            NavigationStack {
                Group {
                    if let note = store.note {
                        content(note: note)
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
            .task { await store.send(.view(.appeared)).finish() }
            .alert($store.scope(state: \.$alert, action: \.alert))
        }

        private func content(note: Note) -> some View {
            VStack(alignment: .leading) {
                switch note.category {
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
                    isVocabulary: note.category == .vocabulary,
                    saveAction: { store.send(.view(.saveButtonTapped)) }
                )
            }
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

#Preview("Vocabulary") {
    let note: Note = .init(
        createdDate: .init(),
        original: "conversation",
        translation: "대화",
        category: .vocabulary
    )
    NoteDetailScreen.Root(
        store: .init(
            initialState: .init(noteID: note.id),
            reducer: {
                NoteDetailScreen.Root.Feature()
            },
            withDependencies: {
                $0.managingNoteUsecase.note = { _ in .success(note) }
            }
        )
    )
}

#Preview("Sentence") {
    let note: Note = .init(
        createdDate: .init(),
        original: "This is a sentence.",
        translation: "문장입니다.",
        category: .sentence
    )
    NoteDetailScreen.Root(
        store: .init(
            initialState: .init(noteID: note.id),
            reducer: {
                NoteDetailScreen.Root.Feature()
            },
            withDependencies: {
                $0.managingNoteUsecase.note = { _ in .success(note) }
            }
        )
    )
}
