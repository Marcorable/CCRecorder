//
//  GeneralSection.swift
//  Presentation
//
//  Created by 김용우 on 6/20/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct GeneralSection: View {
    @State var isLockScreen: Bool = Preference.shared.isLockScreen
    @State var skipTime: SkipTime = Preference.shared.skipTime

    @State var isPresentedTutorial: Bool = false

    var body: some View {
        content
            .onChange(of: isLockScreen)   { Preference.shared.isLockScreen = $0 }
            .onChange(of: skipTime)       { Preference.shared.skipTime = $0 }
            .fullScreenCover(isPresented: $isPresentedTutorial) {
                TutorialView()
            }
    }
    
    var content: some View {
        Section(
            content: {
                Button(
                    action: { isPresentedTutorial.toggle() },
                    label: { Text("앱 사용방법 보기") }
                )
                .tint(.primary)
                HStack {
                    Toggle("화면잠금 해제", isOn: $isLockScreen)
                        .tint(.ccTintColor)
                }
                Picker("건너뛰기 시간 설정", selection: $skipTime) {
                    ForEach(SkipTime.allCases, id: \.self) { time in
                        Text("\(time.description) 초")
                            .tag(time)
                    }
                }
            }, header: {
                Text("일반")
            }
        )
    }
}

#Preview {
    GeneralSection()
}
