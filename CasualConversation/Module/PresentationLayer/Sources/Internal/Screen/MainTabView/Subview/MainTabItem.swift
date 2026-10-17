//
//  MainTabItem.swift
//  Presentation
//
//  Created by 김용우 on 6/6/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct MainTabItem: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    
    var body: some View {
        Button(
            action: { selectedTab = tab },
            label: {
                Spacer()
                Image(systemName: tabItemImageName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(currentTintColor(from: tab))
                Spacer()
            }
        )
    }
    
    // MARK: - Private Methods
    
    private var tabItemImageName: String {
        switch tab {
        case .conversations:     return "rectangle.stack.badge.play.fill"
        case .notes:             return "checklist"
        }
    }
    
    private func currentTintColor(from tab: Tab) -> Color {
        switch tab {
            case .conversations: return tab == selectedTab ? .logoLightRed :  .logoDarkRed
            case .notes:         return tab == selectedTab ? .logoLightBlue : .logoDarkBlue
        }
    }
    
}

#Preview("Conversation 선택") {
    MainTabItem(
        tab: .conversations,
        selectedTab: .constant(.conversations)
    )
}

#Preview("Note 선택") {
    MainTabItem(
        tab: .notes,
        selectedTab: .constant(.notes)
    )
}
