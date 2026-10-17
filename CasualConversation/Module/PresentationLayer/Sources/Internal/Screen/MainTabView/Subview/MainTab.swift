//
//  CCTabItem.swift
//  CCRecorderApp
//
//  Created by 김용우 on 3/24/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct MainTab: View {
    @Binding var selectedTab: Tab
    @Binding var isPresentedRecordView: Bool
    @Binding var isPresentedDeniedAlert: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center) {
                MainTabItem(
                    tab: .conversations,
                    selectedTab: $selectedTab
                )
                Button(
                    action: {
                        AuthorizationChecker.recordPermission { isPermitted in
                            Task { @MainActor in
                                if isPermitted {
                                    isPresentedRecordView.toggle()
                                } else {
                                    isPresentedDeniedAlert.toggle()
                                }
                            }
                        }
                    },
                    label: {
                        Spacer()
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(Color.ccTintColor)
                                .frame(height: 74)
                            Image(systemName: "mic.fill.badge.plus")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                        Spacer()
                    }
                )
                MainTabItem(
                    tab: .notes,
                    selectedTab: $selectedTab
                )
            }
            .padding()
            .background(Color.ccGroupBgColor)
        }
    }
    
}

#Preview("대화 탭") {
    MainTab(
        selectedTab: .constant(.conversations),
        isPresentedRecordView: .constant(false), 
        isPresentedDeniedAlert: .constant(false)
    )
}

#Preview("노트 탭") {
    MainTab(
        selectedTab: .constant(.notes),
        isPresentedRecordView: .constant(false),
        isPresentedDeniedAlert: .constant(false)
    )
}
