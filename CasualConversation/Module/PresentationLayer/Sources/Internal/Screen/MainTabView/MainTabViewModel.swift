//
//  MainTabViewModel.swift
//  Presentation
//
//  Created by 김용우 on 6/25/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Domain

import Combine

final class MainTabViewModel: ObservableObject {
    
    struct Dependency {
        
    }
    
    // MARK: - View Action
    @Published var currentTab: Tab = .conversations
    @Published var isPresentedRecordView: Bool = false
    @Published var isPresentedTutorial: Bool = !Preference.shared.isDoneTutorial
    @Published var isPresentedDeniedAlert: Bool = false
    
}

#if SANDBOX_DEBUG
extension MainTabViewModel {
    
    static var preview: Self { .init() }
    
}

#endif
