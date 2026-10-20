
import SwiftUI

enum ScreenFactory {}

extension ScreenFactory {

    @MainActor
    @ViewBuilder
    static func make(by screen: Screen) -> some View {
        switch screen {
            case .conversationList:
                ConversationListView()

            case .conversationDetail(let conversation):
                ConversationDetailView(conversation: conversation)

            case .setting:
                SettingScreen.Context(
                    viewModel: .init(
                        model: .init(
                            dependency: .init(bundle: .main)
                        )
                    )
                )
        }
    }

}
