//
//  InfomationBoard.swift
//  Presentation
//
//  Created by 김용우 on 6/20/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct InfomationBoard: View {
    @Environment(\.colorScheme) private var systemColorScheme
    
    let dependency: SettingDependency
    
    var body: some View {
        Form {
            VStack(alignment: .center) {
                Image(titleImageName, bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                Text("프린서플어학원 CC Time 프로그램")
                    .font(.headline)
            }
            VStack(alignment: .leading) {
                Text("언제 어디서나 가벼운 인사부터 다양한 주제의 대화를 나누는 영어회화 학습방법입니다")
                    .font(.subheadline)
                Text("주제 및 발음기호 등 학습 정보는 PSE에서 제공합니다")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            Group {
                Link("🔍 프린서플어학원 알아보기", destination: dependency.mainURL)
                Link("☕️ 네이버카페", destination: dependency.cafeURL)
                Link("🖥 e-Learning", destination: dependency.eLearningURL)
                Link("👀 정규반 맛보기 강의", destination: dependency.tasteURL)
                Link("📄 온라인 레벨테스트", destination: dependency.testURL)
                Button("📞 문의전화") {
                    UIApplication.shared.open(dependency.receptionTel)
                }
            }
            .tint(.logoDarkGreen)
        } // AcademyInfos
    }
}

extension InfomationBoard {
    
    private var titleImageName: String {
        if let userSelection = Preference.shared.colorScheme {
            return userSelection == .light ? "pse_title" : "pse_title_border"
        } else {
            return systemColorScheme == .light ? "pse_title" : "pse_title_border"
        }
    }
    
}

#if DEBUG
#Preview {
    InfomationBoard(
        dependency: .init(
            mainURL: .preview,
            cafeURL: .preview,
            eLearningURL: .preview,
            tasteURL: .preview,
            testURL: .preview,
            receptionTel: .preview
        )
    )
}
#endif
