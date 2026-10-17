//
//  RecordViewToolBar.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct RecordViewToolBar: ViewModifier, DismissKeyboardFeature {
    let cancelAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(
                        action: cancelAction,
                        label: {
                            Text("취소")
                                .font(.headline)
                                .foregroundColor(.ccTintColor)
                        }
                    ) // CancelToolBarButton
                }
                ToolbarItem(placement: .keyboard) {
                    Button(
                        action: dismissKeyboard,
                        label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    )
                    .foregroundColor(.ccTintColor)
                    Spacer()
                }
            }
    }
    
}

