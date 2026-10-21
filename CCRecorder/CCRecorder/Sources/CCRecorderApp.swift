
import SwiftUI
import SwiftData

enum LaunchState {
    case preprocess
    case launched
}

@main
struct CCRecorderApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            Note.self,
            Party.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @AppStorage(.isFirstLaunched) private var isFirstLaunched: Bool = true
    @AppStorage(.displayMode) private var displayMode: DisplayMode = .system
    @AppStorage(.isIdleTimerDisabled) private var isIdleTimerDisabled: Bool = false

    @State private var state: LaunchState = .preprocess

    var body: some Scene {
        WindowGroup {
            switch state {
                case .preprocess:
                    LaunchScreen.Context(state: $state)
                    
                case .launched:
                    MainNavigationStack()
                        .overlay {
                            if isFirstLaunched {
                                OnboardScreen.Context(isPrsented: $isFirstLaunched)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut, value: isFirstLaunched)
                        .preferredColorScheme(userColorScheme)
                        .onChange(of: isIdleTimerDisabled, initial: true) {
                            UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
                        }
            }
        }
        .modelContainer(modelContainer)
    }
}

extension CCRecorderApp {

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
