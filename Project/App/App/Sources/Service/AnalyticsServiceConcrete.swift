
import UIKit
import StoreKit

import Domain
import FirebaseAnalytics

actor AnalyticsServiceConcrete {}

extension AnalyticsServiceConcrete: Service {

    @MainActor
    static func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        configureFirebaseAnalytics()
        return true
    }

    private static func configureFirebaseAnalytics() {
        Analytics.setAnalyticsCollectionEnabled(false)

#if DEBUG
        Analytics.setAnalyticsCollectionEnabled(FirebaseService.isDebugEnabled)
#else
        Task {
            let environment: AppStore.Environment?
            do {
                switch try await AppTransaction.shared {
                    case .verified(let transaction):
                        environment = transaction.environment

                    case .unverified:
                        environment = nil
                }
            } catch {
                environment = nil
            }
            Analytics.setAnalyticsCollectionEnabled(environment == .production)
        }
#endif
    }

}

extension AnalyticsServiceConcrete: AnalyticsService {}
