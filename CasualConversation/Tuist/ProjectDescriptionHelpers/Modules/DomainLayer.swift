//
//  DomainLayer.swift
//  CCRecorderAppsManifests
//
//  Created by 김용우 on 2023/10/25.
//

import ProjectDescription

extension TargetDependency {
    public static let domainLayer: TargetDependency = .project(
        target: DomainLayer.name,
        path: .path("../../Module/\(DomainLayer.name)Layer"),
        condition: nil
    )
}

public struct DomainLayer: Module {    
    public static let name: String = "Domain"
    public static let packages: [Package] = [
        .quick,
        .nimble
    ]
    public static let target: Target = .target(
        name: name,
        destinations: .iOS,
        product: .framework,
        productName: nil,
        bundleId: "com.pseapplications.casualconversation.\(name)",
        deploymentTargets: .appTarget,
        infoPlist: .default,
        sources: ["../../Module/\(name)Layer/Sources/**"],
        resources: [],
        copyFiles: nil,
        headers: nil,
        entitlements: nil,
        scripts: [],
        dependencies: [
            .commonLayer
        ],
        settings: nil,
        coreDataModels: [],
        environmentVariables: [:],
        launchArguments: [],
        additionalFiles: [],
        buildRules: [],
        mergedBinaryType: .automatic
    )
    public static let test: Target = .target(
        name: name + "Tests",
        destinations: .iOS,
        product: .unitTests,
        bundleId: "com.pseapplications.\(name)Tests",
        infoPlist: .default,
        sources: ["../../Module/\(name)Layer/Tests/**"],
        resources: [],
        dependencies: [
            .domainLayer,
            
            .quick,
            .nimble
        ]
    )
    public static let schemes: [Scheme] =  [
        .make(name: "\(name)", for: .sandboxDebug, targets: ["\(name)"])
    ]
}
