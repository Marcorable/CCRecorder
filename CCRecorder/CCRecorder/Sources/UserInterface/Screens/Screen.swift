import Foundation

enum Screen: Hashable {
    case conversationList
    case conversationDetail(Conversation)
    case setting
}
