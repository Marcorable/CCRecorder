
import SwiftUI

extension MainScreen {

    struct TabBar: View {
        @Environment(\.colorScheme) private var colorScheme

        let selectedTab: Tab
        let select: (Tab) -> Void
        let record: () -> Void

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
                            .background(recordButtonColor)
                            .clipShape(.circle)
                            .shadow(
                                color: .black,
                                radius: 1,
                                x: 1,
                                y: 1
                            )
                    }
                )
                Item(
                    tab: .noteList,
                    selectedTab: selectedTab,
                    select: select
                )
            }
            .padding(.vertical)
            .background(Color.Surface.Background.grouped)
        }

        private var recordButtonColor: Color {
            colorScheme == .dark ? .Logo.Muted.blue : .Logo.Prominent.blue
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

        private var isSelected: Bool { tab == selectedTab }

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
                    isSelected ? .Logo.Prominent.green : .Logo.Muted.green

                case .noteList:
                    isSelected ? .Logo.Prominent.red : .Logo.Muted.red
            }
        }
    }

}
