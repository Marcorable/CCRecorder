
import SwiftUI

import Presentation

enum LaunchState {
    case preprocess
    case launched
}

@main
struct CCRecorderApp: App {
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
                                try await setup()
                                try await Task.sleep(for: .seconds(2)) // FIXME: Launch Process

                                state = .launched
                            } catch {
                                print("\(Self.self) \(#function) - \(error)")
                            }
                        }

                case .launched:
                    PresentationFactory.rootStack
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
