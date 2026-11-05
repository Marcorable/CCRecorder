
import UIKit

import FirebaseCore

enum FirebaseService {}

extension FirebaseService: Service {

    @MainActor
    static func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

}

extension FirebaseService {

    static var isDebugEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-FIRDebugEnabled")
            && !arguments.contains("-FIRDebugDisabled")
    }

}
