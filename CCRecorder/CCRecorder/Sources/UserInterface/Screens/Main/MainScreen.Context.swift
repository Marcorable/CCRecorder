
import SwiftUI

import NavigationCoordinator

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
                RecordScreen.Context(
                    viewModel: .init(
                        model: .init(
                            dependency: .init(
                                recorder: AudioRecorder(),
                                modelContext: modelContext,
                                fileStore: .init()
                            )
                        )
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
