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
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            Note.self,
            Memeber.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
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
            }
        }
        .modelContainer(modelContainer)
    }
    
}
