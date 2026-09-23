import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var viewCoordinator: ViewCoordinator = .init()
    
    var body: some View {
        NavigationStack(path: $viewCoordinator.path) {
            MainView()
                .navigationDestination(for: Screen.self) {
                    switch $0 {
                        case .conversationList:
                            ConversationListView()
                            
                        case .conversationDetail(let conversation):
                            ConversationDetailView(conversation: conversation)
                            
                        case .setting:
                            SettingView()
                    }
                }
        }
        .environment(viewCoordinator)
        .environment(\.colorScheme, userColorScheme)
    }
    
    private var userColorScheme: ColorScheme {
        return colorScheme
    }
}

#Preview {
    RootView()
}
