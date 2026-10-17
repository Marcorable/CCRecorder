//  CCRecorderAppsManifests
//
//  Created by 김용우 on 2023/10/25.
//

import ProjectDescription

extension TargetDependency {
    public static let dataLayer: TargetDependency = .project(
        target: DataLayer.name,
        path: .path("../../Module/\(DataLayer.name)Layer"),
        condition: nil
    )
}

public struct DataLayer: Module {
    public static let name: String = "Data"
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
        copyFiles: [],
        headers: nil,
        entitlements: nil,
        scripts: [],
        dependencies: [
            .commonLayer,
            
            .domainLayer
        ],
        settings: nil,
//        coreDataModels: [
//            .coreDataModel("../../Module/\(name)Layer/Resources/CasualConversation.xcdatamodeld")
            //.coreDataModel("../../Module/\(name)Layer/Resources/CasualConversation.xcdatamodeld", currentVersion: "CasualConversation")
//        ],
        environmentVariables: [:],
        launchArguments: [],
        additionalFiles: [],
        buildRules: [],
        mergedBinaryType: .automatic
    )
    public static let test: Target = .target(
        name: name + "Tests",
        destinations:  .iOS,
        product: .unitTests,
        bundleId: "com.pseapplications.\(name)Tests",
        deploymentTargets: .appTarget,
        infoPlist: .default,
        sources: ["../../Module/\(name)Layer/Tests/**"],
        resources: [],
        dependencies: [
            .dataLayer,
            
            .quick,
            .nimble
        ]
    )
    public static let schemes: [Scheme] =  [
        .make(name: "\(name)", for: .sandboxDebug, targets: ["\(name)"])
    ]
}
