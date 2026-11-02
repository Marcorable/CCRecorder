
import SwiftUI

import Presentation

@main
struct CCRecorderApp: App {
    @AppStorage(.displayMode) private var displayMode: DisplayMode = .system
    @AppStorage(.isIdleTimerDisabled) private var isIdleTimerDisabled: Bool = false

    enum Status {
        case preprocess
        case launched
        case forcedUpdate
    }

    @State private var status: Status = .preprocess

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            switch status {
                case .preprocess:
                    PresentationFactory.launchScreen
                        .task {
                            do {
                                try await Task.sleep(for: .seconds(2)) // TODO: Launch Process

                                status = .launched
                            } catch {
                                print("\(Self.self) \(#function) - \(error)")
                            }
                        }

                case .launched:
                    PresentationFactory.rootStack
                        .preferredColorScheme(userColorScheme)
                        .onChange(of: isIdleTimerDisabled, initial: true) {
                            UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
                        }

                case .forcedUpdate:
                    PresentationFactory.forcedUpdateScreen
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
