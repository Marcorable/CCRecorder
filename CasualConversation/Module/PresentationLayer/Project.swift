import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project
let project: Project = .init(
    name: PresentationLayer.name + "Layer",
    organizationName: organizationName,
    options: options,
    packages: [
        PresentationLayer.packages
    ].flatMap({ $0 }),
    settings: .settings(configurations: ConfigurationInfo.default),
    targets: [
        PresentationLayer.target,
        PresentationLayer.test
    ],
    schemes: PresentationLayer.schemes,
    fileHeaderTemplate: nil,
    additionalFiles: [],
    resourceSynthesizers: []
)
