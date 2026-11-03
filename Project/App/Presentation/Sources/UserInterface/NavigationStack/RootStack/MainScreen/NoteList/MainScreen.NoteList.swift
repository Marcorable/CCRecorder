
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
