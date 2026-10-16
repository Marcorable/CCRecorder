//
//  DismissKeyboardFeature.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

protocol DismissKeyboardFeature{
    func dismissKeyboard()
}

extension DismissKeyboardFeature{
    
    func dismissKeyboard() {
        UIApplication.shared
            .sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
    }
    
}
