
import ProjectDescription
import ProjectDescriptionHelpers

let packages: [Package] = [
    .remote(
        url: "https://github.com/Marcorable/marcorable-mvvm.git",
        requirement: .exact("0.2.0")
    ),
    .remote(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        requirement: .exact("1.26.1")
    ),
]

let domain = Target.module(
    name: "Domain",
    buildableFolders: ["Domain/Sources"]
)

let domainTests = Target.tests(
    name: "DomainTests",
    buildableFolders: ["Domain/Tests"],
    dependencies: [
        .target(name: "Domain"),
    ]
)

let data = Target.module(
    name: "Data",
    buildableFolders: ["Data/Sources"],
    dependencies: [
        .target(name: "Domain"),
    ]
)

let dataTests = Target.tests(
    name: "DataTests",
    buildableFolders: ["Data/Tests"],
    dependencies: [
        .target(name: "Data"),
        .target(name: "Domain"),
    ]
)

let presentation = Target.module(
    name: "Presentation",
    buildableFolders: ["Presentation/Sources"],
    dependencies: [
        .target(name: "Domain"),
    ]
)

let app = Target.target(
    name: "CCRecorder",
    destinations: CCRecorderProject.destinations,
    product: .app,
    bundleId: "com.pseapplications.CasualConversation",
    deploymentTargets: CCRecorderProject.deploymentTargets,
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": "Casual Conversation",
            "CFBundleShortVersionString": "1.2.0",
            "CFBundleVersion": "1",
            "LSApplicationCategoryType": "public.app-category.productivity",
            "NSMicrophoneUsageDescription": "사용자의 대화를 녹음 하기위해 앱에서 마이크 접근 허용을 요청합니다 (필수)",
            "UIApplicationSceneManifest": [
                "UIApplicationSupportsMultipleScenes": false,
            ],
            "UILaunchScreen": [:],
            "UISupportedInterfaceOrientations": [
                "UIInterfaceOrientationPortrait",
            ],
        ]
    ),
    buildableFolders: [
        "App/Sources",
        "App/Resources",
    ],
    dependencies: [
        .target(name: "Presentation"),
        .target(name: "Domain"),
        .target(name: "Data"),
        .package(product: "NavigationCoordinator"),
        .package(product: "ComposableArchitecture"),
    ],
    settings: .settings(
        base: [
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "DEVELOPMENT_ASSET_PATHS": "\"App/Resources/Preview Content\"",
            "DEVELOPMENT_TEAM": "9486RJPBM5",
            "ENABLE_PREVIEWS": "YES",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2",
        ]
    )
)

let tests = Target.tests(
    name: "CCRecorderTests",
    buildableFolders: ["Tests/Unit"],
    dependencies: [
        .target(name: "CCRecorder"),
    ]
)

let uiTests = Target.target(
    name: "CCRecorderUITests",
    destinations: CCRecorderProject.destinations,
    product: .uiTests,
    bundleId: "com.pseapplications.CasualConversation.UITests",
    deploymentTargets: CCRecorderProject.deploymentTargets,
    infoPlist: .default,
    buildableFolders: ["Tests/UI"],
    dependencies: [
        .target(name: "CCRecorder"),
    ],
    settings: .ccRecorder
)

let project = Project(
    name: "App",
    organizationName: CCRecorderProject.organizationName,
    options: .options(automaticSchemesOptions: .disabled),
    packages: packages,
    settings: .ccRecorder,
    targets: [
        domain,
        domainTests,
        data,
        dataTests,
        presentation,
        app,
        tests,
        uiTests,
    ],
    schemes: [
        .scheme(
            name: "Presentation",
            shared: true,
            buildAction: .buildAction(targets: ["Presentation"])
        ),
        .scheme(
            name: "Domain",
            shared: true,
            buildAction: .buildAction(targets: ["Domain"]),
            testAction: .targets(["DomainTests"])
        ),
        .scheme(
            name: "Data",
            shared: true,
            buildAction: .buildAction(targets: ["Data"]),
            testAction: .targets(["DataTests"])
        ),
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(targets: ["CCRecorder"]),
            testAction: .testPlans(
                [
                    .relativeToManifest("Tests/Plans/App.xctestplan"),
                    .relativeToManifest("Tests/Plans/CI-Unit.xctestplan"),
                    .relativeToManifest("Tests/Plans/Local-UI.xctestplan"),
                ],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug, executable: "CCRecorder"),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release, executable: "CCRecorder"),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
    ]
)
