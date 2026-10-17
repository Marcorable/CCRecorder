//
//  View+.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/14.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import SwiftUI

extension View {
    
    func toolbar(_ content: some ViewModifier) -> some View {
        self.modifier(content)
    }
	
}
