//
//  CasualConversationApp.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/23.
//

import SwiftUI
import Presentation

enum LaunchStatus {
    case preprocess
    case launched(any ViewFactory)
    case excepted
}

@main
struct CasualConversationApp: App {
    
    @State private var launchStatus: LaunchStatus = .preprocess
    
    var body: some Scene {
        WindowGroup {
            switch launchStatus {
                case .launched(let viewFactory):
                    viewFactory.makeRootView()
                    
                default:
                    LaunchScreenView(launchStatus: $launchStatus)
                    
            }
        }
    }
    
}
