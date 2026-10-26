
import ProjectDescription

public enum CCRecorderProject {
    public static let organizationName = "pseapplications"
    public static let destinations = Destinations.iOS
    public static let deploymentTargets = DeploymentTargets.iOS("18.0")
}

public extension Settings {

    static var ccRecorder: Self {
        .settings(
            base: [
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
                "DEVELOPMENT_TEAM": "9486RJPBM5",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_VERSION": "5.0",
            ]
        )
    }

}

public extension Target {

    static func module(
        name: String,
        product: Product = .framework,
        buildableFolders: [BuildableFolder],
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: name,
            destinations: CCRecorderProject.destinations,
            product: product,
            bundleId: "com.\(CCRecorderProject.organizationName).\(name)",
            deploymentTargets: CCRecorderProject.deploymentTargets,
            infoPlist: .default,
            resources: resources,
            buildableFolders: buildableFolders,
            dependencies: dependencies,
            settings: .ccRecorder
        )
    }

    static func tests(
        name: String,
        buildableFolders: [BuildableFolder],
        dependencies: [TargetDependency]
    ) -> Self {
        .target(
            name: name,
            destinations: CCRecorderProject.destinations,
            product: .unitTests,
            bundleId: "com.\(CCRecorderProject.organizationName).\(name)",
            deploymentTargets: CCRecorderProject.deploymentTargets,
            infoPlist: .default,
            buildableFolders: buildableFolders,
            dependencies: dependencies,
            settings: .ccRecorder
        )
    }

}
