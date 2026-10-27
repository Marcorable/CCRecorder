
import SwiftUI
import SwiftData

import Presentation

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
                    PresentationFactory.launchScreen
                        .task {
                            do {
                                try AudioSessionController.configure()
                            } catch {
                                /// 세션 설정에 실패해도 앱은 진입시키고, 녹음 시도 시점에 다시 알린다.
                                print("\(Self.self) \(#function) - \(error)")
                            }

                            do {
                                _ = try LegacyStoreMigrator().migrateIfNeeded(into: modelContainer.mainContext)
                            } catch {
                                print("\(Self.self) \(#function) - \(error)")
                            }

                            do {
                                try await Task.sleep(for: .seconds(2)) // FIXME: Launch Process

                                state = .launched
                            } catch {

                            }
                        }

                case .launched:
                    MainNavigationStack()
                        .fullScreenCover(isPresented: $isFirstLaunched) {
                            PresentationFactory.onboardScreen
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
