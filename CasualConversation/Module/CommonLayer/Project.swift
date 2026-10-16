import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project
let project: Project = .init(
    name: CommonLayer.name + "Layer",
    organizationName: organizationName,
    options: options,
    packages: [
        CommonLayer.packages
    ].flatMap({ $0 }),
    settings: .settings(configurations: ConfigurationInfo.default),
    targets: [
        CommonLayer.target,
        CommonLayer.test
    ],
    schemes: CommonLayer.schemes,
    fileHeaderTemplate: nil,
    additionalFiles: [],
    resourceSynthesizers: []
)
