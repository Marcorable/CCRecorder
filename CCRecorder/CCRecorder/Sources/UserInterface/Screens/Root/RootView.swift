import SwiftUI

struct RootView: View {
    @AppStorage(.Key.displayMode) private var displayMode: DisplayMode = .system
    @AppStorage(.Key.isIdleTimerDisabled) private var isIdleTimerDisabled: Bool = false
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
                            SettingScreen.Context(
                                viewModel: .init(
                                    model: .init(
                                        dependency: .init(bundle: .main)
                                    )
                                )
                            )
                    }
                }
        }
        .environment(viewCoordinator)
        .preferredColorScheme(userColorScheme)
        .onChange(of: isIdleTimerDisabled, initial: true) {
            UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
        }
    }
    
    private var userColorScheme: ColorScheme? {
        switch displayMode {
            case .system:
                nil

            case .light:
                .light

            case .dark:
                .dark
        }
    }
}

#Preview {
    RootView()
}
