import SwiftUI

enum Tab {
    case conversationList
    case noteList
}

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
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
        .background(backgroudColor)
        .fullScreenCover(isPresented: $isPresentedModal) {
            RecordView()
        }
        .toolbar {
            MainViewToolbar()
        }
    }
    
}

extension MainView {
    
    private var backgroudColor: Color {
        colorScheme == .dark ? .Dark.background : .Light.background
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
