//
//  MainViewToolBar.swift
//  Presentation
//
//  Created by 김용우 on 6/15/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct MainViewToolBar<ViewContent: View>: ViewModifier {
    let destination: ViewContent
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: destination,
                        label: { Image(systemName: "gear") }
                    )
                }
            }
    }
    
}
