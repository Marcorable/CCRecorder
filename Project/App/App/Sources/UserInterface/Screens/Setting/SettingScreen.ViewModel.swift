
import Foundation
import Observation

extension SettingScreen {

    @MainActor
    @Observable
    final class ViewModel {
        var presentedFullScreenCover: Status.FullScreenCover?

        @ObservationIgnored private let model: Model

        init(model: Model) {
            self.model = model
        }
    }

}

extension SettingScreen.ViewModel {

    var informationSection: SettingScreen.InformationSection.ViewModel {
        .init(model: model.informationSection)
    }

    var teamSection: SettingScreen.TeamSection.ViewModel {
        .init(model: model.teamSection)
    }

}

extension SettingScreen.ViewModel {
    typealias Intent = SettingScreen.Intent

    func reduce(by intent: Intent) {
        switch intent {
            case .rewindButtonTapped:
                presentedFullScreenCover = .tutorial
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
