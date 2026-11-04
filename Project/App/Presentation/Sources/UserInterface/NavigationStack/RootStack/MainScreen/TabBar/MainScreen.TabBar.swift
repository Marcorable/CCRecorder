
import SwiftUI

extension MainScreen {

    struct TabBar: View {
        @Environment(\.colorScheme) private var colorScheme

        let selectedTab: Tab
        let select: (Tab) -> Void
        let record: () -> Void
        let isAbleToRequestRecording: Bool

        var body: some View {
            HStack {
                Item(
                    tab: .conversationList,
                    selectedTab: selectedTab,
                    select: select
                )
                Button(
                    action: record,
                    label: {
                        Image(systemName: "mic.fill.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                            .padding()
                            .background(
                                colorScheme == .dark
                                    ? Color(asset: Asset.Logo.Muted.blue)
                                    : Color(asset: Asset.Logo.Prominent.blue)
                            )
                            .clipShape(.circle)
                            .shadow(
                                color: .black,
                                radius: 1,
                                x: 1,
                                y: 1
                            )
                    }
                )
                .disabled(!isAbleToRequestRecording)
                Item(
                    tab: .noteList,
                    selectedTab: selectedTab,
                    select: select
                )
            }
            .padding(.vertical)
            .background(Color(asset: Asset.Surface.Background.grouped))
        }
    }

}

extension MainScreen.TabBar {

    struct Item: View {
        let tab: MainScreen.Tab
        let selectedTab: MainScreen.Tab
        let select: (MainScreen.Tab) -> Void

        var body: some View {
            Button(
                action: { select(tab) },
                label: {
                    Image(systemName: tabItemImageName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(currentTintColor)
                }
            )
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(accessibilityIdentifier)
        }

        private var tabItemImageName: String {
            switch tab {
                case .conversationList:     "rectangle.stack.badge.play.fill"
                case .noteList:             "checklist"
            }
        }

        private var accessibilityIdentifier: String {
            switch tab {
                case .conversationList:     "mainTab.conversation"
                case .noteList:             "mainTab.note"
            }
        }

        private var currentTintColor: Color {
            switch tab {
                case .conversationList:
                    tab == selectedTab
                        ? Color(asset: Asset.Logo.Prominent.green)
                        : Color(asset: Asset.Logo.Muted.green)

                case .noteList:
                    tab == selectedTab
                        ? Color(asset: Asset.Logo.Prominent.red)
                        : Color(asset: Asset.Logo.Muted.red)
            }
        }
    }

}

#Preview {
    MainScreen.TabBar(
        selectedTab: .conversationList,
        select: { _ in },
        record: {},
        isAbleToRequestRecording: true
    )
}
