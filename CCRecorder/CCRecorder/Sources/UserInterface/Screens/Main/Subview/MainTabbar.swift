import SwiftUI

struct MainTabbar: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedTab: Tab
    @Binding var isPresentedModal: Bool
    
    var body: some View {
        HStack {
            Spacer()
            MainTabItem(
                tab: .conversationList,
                selectedTab: $selectedTab
            )
            Spacer()
            Button(
                action: { isPresentedModal.toggle() },
                label: {
                    Spacer()
                    ZStack(alignment: .center) {
                        Image(systemName: "mic.fill.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                            .padding()
                            .background(recordButtonColor)
                            .clipShape(.circle)
                    }
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                    Spacer()
                }
            )
            Spacer()
            MainTabItem(
                tab: .noteList,
                selectedTab: $selectedTab
            )
            Spacer()
        }
        .padding(.vertical)
        .background(backgroundColor)
    }
    
    private var backgroundColor: Color {
        .Surface.Background.grouped
    }
    
    private var recordButtonColor: Color {
        colorScheme == .dark ? .Logo.Muted.blue : .Logo.Prominent.blue
    }
    
}

fileprivate struct MainTabItem: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    
    var body: some View {
        Button(
            action: { selectedTab = tab },
            label: {
                Spacer()
                Image(systemName: tabItemImageName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(currentTintColor)
                Spacer()
            }
        )
        .accessibilityIdentifier(accessibilityIdentifier)
    }
    
    private var tabItemImageName: String {
        switch tab {
            case .conversationList:     "rectangle.stack.badge.play.fill"
            case .noteList:             "checklist"
        }
    }
    
    private var isSelected: Bool { tab == selectedTab }

    private var accessibilityIdentifier: String {
        switch tab {
            case .conversationList:     "mainTab.conversation"
            case .noteList:             "mainTab.note"
        }
    }
    
    private var currentTintColor: Color {
        switch tab {
            case .conversationList:     isSelected ? .Logo.Prominent.green : .Logo.Muted.green
            case .noteList:             isSelected ? .Logo.Prominent.red : .Logo.Muted.red
        }
    }
    
}

#Preview("대화 탭") {
    MainTabbar(
        selectedTab: .constant(.conversationList),
        isPresentedModal: .constant(false)
    )
}

#Preview("노트 탭") {
    MainTabbar(
        selectedTab: .constant(.noteList),
        isPresentedModal: .constant(false)
    )
}
