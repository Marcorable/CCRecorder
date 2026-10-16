//
//  PresentationFactory.swift
//  Presentation
//
//  Created by 김용우 on 6/3/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common
import Foundation.NSURL

public enum PresentationFactory {
    
    public static var mainURL: URL!
    public static var cafeURL: URL!
    public static var eLearningURL: URL!
    public static var tasteURL: URL!
    public static var testURL: URL!
    public static var receptionTel: URL!
    
    public static func setup(
        mainURL: URL,
        cafeURL: URL,
        eLearningURL: URL,
        tasteURL: URL,
        testURL: URL,
        receptionTel: URL
    ) {
        Self.mainURL = mainURL
        Self.cafeURL = cafeURL
        Self.eLearningURL = eLearningURL
        Self.tasteURL = tasteURL
        Self.testURL = testURL
        Self.receptionTel = receptionTel
        
        PresentationAppearance.setup()
    }
    
    public static func makeViewFactory(_ container: DependencyContainer) -> some ViewFactory {
        ScreenMaker(
            dependency: .init(container: container)
        )
    }
    
}
