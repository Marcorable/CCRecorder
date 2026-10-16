//
//  MainTabView.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/23.
//

import SwiftUI

struct MainTabView: View, OpenSettingFeature {
	
    // MARK: - Dependency
	@EnvironmentObject private var viewMaker: ScreenMaker
    
    @StateObject var viewModel: MainTabViewModel
	
    // MARK: - View Render
    var content: some View {
        ZStack {
            switch viewModel.currentTab {
                case .conversations:        viewMaker.makeView(.conversationList)
                case .notes:                viewMaker.makeView(.noteSet(nil))
            }
        }
        .overlay {
            MainTab(
                selectedTab: $viewModel.currentTab,
                isPresentedRecordView: $viewModel.isPresentedRecordView,
                isPresentedDeniedAlert: $viewModel.isPresentedDeniedAlert
            )
        }
        .background(Color.ccBgColor)
        .navigationTitle(navigationTitle)
        .toolbar(
            MainViewToolBar(
                destination: viewMaker.makeView(.setting)
            )
        )
    }
    
    
    
    var body: some View {
        NavigationView {
            content
                .navigationBarTitleDisplayMode(.large)
                .fullScreenCover(isPresented: $viewModel.isPresentedRecordView) {
                    viewMaker.makeView(.record)
                }
                .fullScreenCover(isPresented: $viewModel.isPresentedTutorial) {
                    TutorialView()
                }
                .alert(
                    "마이크 접근 허용 필요",
                    isPresented: $viewModel.isPresentedDeniedAlert,
                    actions: { Button("확인", role: .cancel, action: openSetting) },
                    message: {
                        Text("설정 > CasualConversation > CASUALCONVERSATION 접근허용 > 마이크 허용\n 스위치를 허용해주세요")
                    }
                )
        }
    }

    // MARK: - Private Methods
    private var navigationTitle: String {
        switch viewModel.currentTab {
            case .conversations:    return "Conversations"
            case .notes:            return "Notes"
        }
    }
    
}

// MARK: - Preview
#if SANDBOX_DEBUG
#Preview("라이트 모드") {
    MainTabView(viewModel: .preview)
        .preferredColorScheme(.light)
}

#Preview("다크 모드") {
    MainTabView(viewModel: .preview)
        .preferredColorScheme(.dark)
}
#endif
