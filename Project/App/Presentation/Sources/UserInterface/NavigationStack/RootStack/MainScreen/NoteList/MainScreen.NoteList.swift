
import SwiftUI

import ComposableArchitecture

extension MainScreen {

    struct NoteList: View {
        let store: StoreOf<Feature>

        var body: some View {
            NoteBoard(
                rows: store.rows,
                onTap: { store.send(.view(.noteTapped($0))) },
                onDelete: { store.send(.view(.deleteRequested($0))) }
            )
            .accessibilityIdentifier("main.noteList")
            .navigationTitle("Note")
            .task {
                await store.send(.view(.task)).finish()
            }
        }
    }

}

#Preview {
    NavigationStack {
        MainScreen.NoteList(
            store: .init(
                initialState: .init(),
                reducer: { MainScreen.NoteList.Feature() },
                withDependencies: {
                    $0.managingNoteUsecase.loadNotes = {
                        .success([
                            .init(
                                createdDate: .init(),
                                original: "conversation",
                                translation: "대화",
                                category: .vocabulary
                            ),
                            .init(
                                createdDate: .init(),
                                original: "How have you been?",
                                translation: "어떻게 지냈어요?",
                                category: .sentence
                            ),
                        ])
                    }
                }
            )
        )
    }
}
