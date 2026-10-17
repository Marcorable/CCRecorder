//
//  ViewFactory.swift
//  Presentation
//
//  Created by 김용우 on 6/3/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

public protocol ViewFactory {
    func makeRootView() -> AnyView
}
