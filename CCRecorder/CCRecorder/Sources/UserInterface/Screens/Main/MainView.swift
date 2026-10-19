import SwiftUI

enum Tab {
    case conversationList
    case noteList
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ViewCoordinator.self) private var viewCoordinator
    
    @State private var selectedTab: Tab = .conversationList
    @State private var isPresentedModal: Bool = false

    var body: some View {
        VStack {
            switch selectedTab {
                case .conversationList:     ConversationListView()
                case .noteList:             NoteListView()
            }
            MainTabbar(
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
            MainViewToolbar()
        }
    }
    
}

fileprivate struct MainViewToolbar: ToolbarContent {
    @Environment(ViewCoordinator.self) private var viewCoordinator
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(
                action: { viewCoordinator.push(.setting) },
                label: { 
                    Image(systemName: "gear")
                        .foregroundStyle(.accent)
                }
            )
        }
    }
    
}


#Preview {
    MainView()
        .environment(ViewCoordinator())
}
