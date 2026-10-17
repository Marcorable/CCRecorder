//
//  UnclassfiedSection.swift
//  Presentation
//
//  Created by 김용우 on 6/20/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct UnclassfiedSection: View {
    
    var body: some View {
        Section(
            content: {
                //            NavigationLink(destination: {
                //                Text("오픈소스 라이선스")
                //            }, label: {
                //                Text("오픈소스 라이선스")
                //            })
                HStack {
                    Text("버전")
                    Spacer()
                    Text(Preference.shared.appVersion)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                NavigationLink(
                    destination: {
                        TeamMateInfoView()
                    }, label: {
                        Text("개발자 정보")
                    }
                )
            }, header: {
                Text("앱 정보")
            }
        )
    }
}

#Preview {
    UnclassfiedSection()
}
