
import Foundation

enum SettingScreen {

    enum Intent: Hashable {
        case rewindButtonTapped
    }

    enum Status: Hashable {

        enum FullScreenCover: IdentifiableFeature {
            case tutorial
        }

    }

}
