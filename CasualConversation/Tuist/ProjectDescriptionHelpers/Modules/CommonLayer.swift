//
//  CommonLayer.swift
//  CCRecorderAppsManifests
//
//  Created by 김용우 on 2023/10/25.
//

import ProjectDescription

extension TargetDependency {
    public static let commonLayer: TargetDependency = .project(
        target: CommonLayer.name,
        path: .path("../../Module/\(CommonLayer.name)Layer"),
        condition: nil
    )
}

public struct CommonLayer: Module {
    public static let name: String = "Common"
    public static let packages: [Package] = [
        .swinject,
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
            .swinject
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
            .commonLayer,
            
            .quick,
            .nimble
        ]
    )
    public static let schemes: [Scheme] = [
        .make(name: "\(name)", for: .sandboxDebug, targets: ["\(name)"])
    ]
}
