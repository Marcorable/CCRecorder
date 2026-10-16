//
//  LaunchScreenView.swift
//  CCRecorderApp
//
//  Created by 김용우 on 6/2/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common
import Data
import Domain
import Presentation

import SwiftUI

struct LaunchScreenView: View {
    
    @Binding var launchStatus: LaunchStatus
    
    @State var mainURL: URL!
    @State var cafeURL: URL!
    @State var eLearningURL: URL!
    @State var tasteURL: URL!
    @State var testURL: URL!
    @State var receptionTel: URL!
    
    var body: some View {
        Image("homex_00")
            .resizable()
            .scaledToFill()
            .background {
                Image("homex_00")
                    .resizable()
                    .ignoresSafeArea()
            }
            .task {
                // MARK: - setup App
                setupAVFAudio()
                setupAppConfiguration()
                
                // MARK: - setup Modules
                DataFactory.setup()
                DomainFactory.setup()
                PresentationFactory.setup(
                    mainURL: mainURL,
                    cafeURL: cafeURL,
                    eLearningURL: eLearningURL,
                    tasteURL: tasteURL,
                    testURL: testURL,
                    receptionTel: receptionTel
                )
                
                // MARK: - register
                let container = DependencyContainer()
                DataFactory.register(container)
                DomainFactory.register(container)
                let viewFactory = PresentationFactory.makeViewFactory(container)
                
                Thread.sleep(forTimeInterval: 2.0) // 임시 로딩 시간
                
                await MainActor.run {
                    launchStatus = .launched(viewFactory)
                }
            }
    }
    
//    // MARK: - Repository
//    private lazy var fileManagerReposotiry: FileManagerRepositoryProtocol = FileManagerRepository()
    
}

#Preview {
    LaunchScreenView(launchStatus: .constant(.preprocess))
}
