
import Foundation
import Observation

extension SettingScreen {

    @MainActor
    @Observable
    final class ViewModel {
        private(set) var isPresentedTutorial: Bool = false

        @ObservationIgnored private let model: Model

        init(model: Model) {
            self.model = model
        }
    }

}

extension SettingScreen.ViewModel {

    var appVersion: String? { model.appVersion }

}

extension SettingScreen.ViewModel {
    typealias Intent = SettingScreen.Intent

    func reduce(by intent: Intent) {
        switch intent {
            case .presentTutorial:
                isPresentedTutorial = true

            case .dismissTutorial:
                isPresentedTutorial = false
        }
    }

}

#if DEBUG
extension SettingScreen.ViewModel {

    static var mock: SettingScreen.ViewModel {
        .init(model: .mock)
    }

}
#endif
