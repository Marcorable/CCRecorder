//
//  Dependencies.swift
//  ProjectDescriptionHelpers
//
//  Created by 김용우 on 6/2/24.
//

import ProjectDescription

extension TargetDependency {
    
    static let swinject: Self = .package(product: "Swinject")
    static let quick: Self = .package(product: "Quick")
    static let nimble: Self = .package(product: "Nimble")
    
}


extension Package {
    
    static let swinject: Self = .remote(
        url: "https://github.com/Swinject/Swinject.git",
        requirement: .upToNextMajor(from: .init(2, 8, 0)))
    static let quick: Self = .remote(
        url: "https://github.com/Quick/Quick.git",
        requirement: .upToNextMajor(from: .init(7, 0, 0))
    )
    static let nimble: Self = .remote(
        url: "https://github.com/Quick/Nimble.git",
        requirement: .upToNextMajor(from: .init(13, 0, 0))
    )
        
}
