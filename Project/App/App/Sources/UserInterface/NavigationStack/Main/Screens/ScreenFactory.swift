
import SwiftUI

import Presentation

enum ScreenFactory {}

extension ScreenFactory {

    @MainActor
    @ViewBuilder
    static func make(by screen: Screen) -> some View {
        switch screen {
            case .conversationDetail(let conversation):
                ConversationDetailScreen.Context(conversation: conversation)

            case .setting:
                PresentationFactory.settingScreen
        }
    }

}
