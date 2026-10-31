
import Foundation

extension RootStack {

    enum Route: Hashable, Sendable {
        case main
        case conversationDetail(UUID)
        case setting
    }

}
