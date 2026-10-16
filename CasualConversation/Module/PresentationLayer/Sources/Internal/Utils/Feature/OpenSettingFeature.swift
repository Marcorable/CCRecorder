//
//  OpenSettingFeature.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

protocol OpenSettingFeature{
    func openSetting()
}

extension OpenSettingFeature{
    
    func openSetting() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url)
        }
    }
    
}

