
import UIKit

import Domain
import FirebaseCrashlytics

actor CrashReportingServiceConcrete {}

extension CrashReportingServiceConcrete: Service {

    @MainActor
    static func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        configureFirebaseCrashlytics()
        return true
    }

    private static func configureFirebaseCrashlytics() {
        let enabled: Bool
#if DEBUG
        enabled = FirebaseService.isDebugEnabled
#else
        enabled = true
#endif
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }

}

extension CrashReportingServiceConcrete: CrashReportingService {}
