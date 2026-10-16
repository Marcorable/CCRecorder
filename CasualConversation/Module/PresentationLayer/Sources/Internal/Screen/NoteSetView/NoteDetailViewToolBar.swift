//
//  NoteDetailViewToolBar.swift
//  Presentation
//
//  Created by 김용우 on 6/16/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct NoteDetailViewToolBar: ViewModifier {
    let isEdited: Bool
    let title: String
    let imageSystemName: String
    let saveAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: imageSystemName)
                            .foregroundColor(.logoLightRed)
                        Text(title)
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button (
                        action: {
                            saveAction()
                        }, label: {
                            Text("저장")
                                .font(.headline)
                                .foregroundColor(.logoDarkGreen)
                        }
                    )
                    .disabled(!isEdited)
                    .opacity(isEdited ? 1 : 0.3)
                }
            }
    }
    
}
