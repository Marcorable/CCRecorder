import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project
let project: Project = .init(
    name: DataLayer.name + "Layer",
    organizationName: organizationName,
    options: options,
    packages: [
        DataLayer.packages
    ].flatMap({ $0 }),
    settings: .settings(configurations: ConfigurationInfo.default),
    targets: [
        DataLayer.target,
        DataLayer.test
    ],
    schemes: DataLayer.schemes,
    fileHeaderTemplate: nil,
    additionalFiles: [],
    resourceSynthesizers: []
)
