//
//  CCRecorderApp.swift
//  CCRecorder
//
//  Created by 김용우 on 9/6/24.
//

import SwiftUI
import SwiftData

enum LaunchState {
    case preprocess
    case launched
}

@main
struct CCRecorderApp: App {
    
    @AppStorage(.Key.isFirstLaunched) private var isFirstLaunched: Bool = true
    @State private var state: LaunchState = .preprocess

    var body: some Scene {
        WindowGroup {
            switch state {
                case .preprocess:
                    LaunchScreenView(state: $state)
                    
                case .launched:
                    Color.clear
                        .overlay {
                            RootView()
                        }
                        .overlay {
                            if isFirstLaunched {
                                OnboardView(isPrsented: $isFirstLaunched)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut, value: isFirstLaunched)
                        .modelContainer(
                            for: [
                                Conversation.self,
                                Note.self
                            ]
                        )
            }
        }
    }
    
}
