
import Foundation

import Domain

extension RootStack {

    enum Route: Hashable, Sendable {
        case main
        case conversationDetail(Conversation)
        case setting
    }

}
