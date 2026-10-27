
import SwiftUI

import NavigationCoordinator
import ComposableArchitecture

extension MainScreen {

    struct Context: View {
        @Environment(\.modelContext) private var modelContext

        @State private var selectedTab: Tab = .conversationList
        @State private var isPresentedModal: Bool = false

        var body: some View {
            VStack {
                switch selectedTab {
                    case .conversationList:     ConversationListScreen.Context()
                    case .noteList:             NoteListScreen.Context()
                }
                TabBar(
                    selectedTab: $selectedTab,
                    isPresentedModal: $isPresentedModal
                )
            }
            .background(Color.Surface.Background.primary)
            .fullScreenCover(isPresented: $isPresentedModal) {
                let fileStore = RecordFileStore()
                RecordScreen.Root(
                    store: .init(
                        initialState: .init(),
                        reducer: { RecordScreen.Root.Feature() },
                        withDependencies: {
                            $0.recordUsecase = .live(
                                service: AudioRecorder(store: fileStore)
                            )
                            $0.saveConversationUsecase = .live(
                                repository: ConversationRepositoryConcrete(
                                    modelContext: modelContext
                                ),
                                fileStore: fileStore
                            )
                        }
                    )
                )
            }
            .toolbar {
                Toolbar()
            }
        }
    }

}

extension MainScreen.Context {

    struct Toolbar: ToolbarContent {
        @Environment(Navigator<Screen>.self) private var navigator

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    action: { navigator.push(.setting) },
                    label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.accent)
                    }
                )
            }
        }
    }

}

#Preview {
    MainScreen.Context()
        .environment(Navigator<Screen>())
}
