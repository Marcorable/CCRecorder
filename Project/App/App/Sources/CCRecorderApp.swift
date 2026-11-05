
import SwiftUI

import Presentation

@main
struct CCRecorderApp: App {
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
                        .onChange(of: isIdleTimerDisabled, initial: true) {
                            UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
                        }

                case .forcedUpdate:
                    PresentationFactory.forcedUpdateScreen
            }
        }
    }
}
