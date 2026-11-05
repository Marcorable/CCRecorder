
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
        let crashlytics = Crashlytics.crashlytics()
#if DEBUG
        crashlytics.setCrashlyticsCollectionEnabled(false)
        if FirebaseService.isDebugEnabled {
            crashlytics.sendUnsentReports()
        }
#else
        crashlytics.setCrashlyticsCollectionEnabled(true)
#endif
    }

}

extension CrashReportingServiceConcrete: CrashReportingService {}
