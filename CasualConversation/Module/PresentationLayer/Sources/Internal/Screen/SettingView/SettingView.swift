//
//  SettingView.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/09.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import SwiftUI

struct SettingDependency {
    let mainURL: URL
    let cafeURL: URL
    let eLearningURL: URL
    let tasteURL: URL
    let testURL: URL
    let receptionTel: URL
}

struct SettingView: View {
    
    let dependency: SettingDependency
	
	@Environment(\.colorScheme) private var systemColorScheme
    
    @State var displayMode: DisplayMode = Preference.shared.displayMode
    
    var body: some View {
		content
            .onChange(of: displayMode)    { Preference.shared.displayMode = $0 }
    }
	
    var content: some View {
        VStack {
            Form {
                NavigationLink(
                    destination: InfomationBoard(dependency: dependency),
                    label: {
                        HStack {
                            Image(logoImageName, bundle: .module)
                                .resizable()
                                .frame(width: 41.7, height: 48)
                            Text("What is Casual Conversation?")
                                .font(.headline)
                        }
                    }
                )
                GeneralSection()
                Section(
                    content: {
                        Picker("디스플레이 모드 설정", selection: $displayMode) {
                            ForEach(DisplayMode.allCases, id: \.self) { condition in
                                Text(condition.description)
                                    .tag(condition)
                            }
                        } // DarkMode
                    }, header: {
                        Text("테마")
                    }
                ) // ThemeSection
                FeedbackSection()
                UnclassfiedSection()
            }
            .listStyle(.grouped)
            
            Text("@2022. All rights reserved by Team Marcoda.")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .navigationTitle("Setting")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}

extension SettingView {
    
    private var logoImageName: String {
        if let userSelection = Preference.shared.colorScheme {
            return userSelection == .light ? "pse_logo" : "pse_logo_border"
        } else {
            return systemColorScheme == .light ? "pse_logo" : "pse_logo_border"
        }
    }
    
}

#if DEBUG
extension URL {
    static var preview: Self = URL(fileURLWithPath: "")
}

#Preview {
    SettingView(
        dependency: .init(
            mainURL: .preview,
            cafeURL: .preview,
            eLearningURL: .preview,
            tasteURL: .preview,
            testURL: .preview,
            receptionTel: .preview
        )
    )
    .preferredColorScheme(.light)
}
#Preview {
    SettingView(
        dependency: .init(
            mainURL: .preview,
            cafeURL: .preview,
            eLearningURL: .preview,
            tasteURL: .preview,
            testURL: .preview,
            receptionTel: .preview
        )
    )
    .preferredColorScheme(.dark)
}
#endif
