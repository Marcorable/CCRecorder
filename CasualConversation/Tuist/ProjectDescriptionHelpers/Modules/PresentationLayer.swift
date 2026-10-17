//
//  PresentationLayer.swift
//  CCRecorderAppsManifests
//
//  Created by 김용우 on 2023/10/25.
//

import ProjectDescription

extension TargetDependency {
    public static let presentationLayer: TargetDependency = .project(
        target: PresentationLayer.name,
        path: .path("../../Module/\(PresentationLayer.name)Layer"),
        condition: nil
    )
}

public struct PresentationLayer: Module {
    public static let name: String = "Presentation"
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
        resources: ["../../Module/\(name)Layer/Resources/**"],
        copyFiles: nil,
        headers: nil,
        entitlements: nil,
        scripts: [],
        dependencies: [
            .commonLayer,
            
            .domainLayer
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
            .presentationLayer,
            
            .quick,
            .nimble
        ]
    )
    public static let schemes: [Scheme] =  [
        .make(name: "\(name)", for: .sandboxDebug, targets: ["\(name)"])
    ]
}

