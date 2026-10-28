
import Foundation

enum SettingScreen {
    enum Intent: Hashable {
        case rewindButtonTapped
    }

    enum Status: Hashable {
        enum FullScreenCover: Hashable, Identifiable {
            case tutorial

            var id: Self { self }
        }
    }
}
