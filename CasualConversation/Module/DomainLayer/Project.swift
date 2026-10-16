import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Project
let project: Project = .init(
    name: DomainLayer.name + "Layer",
    organizationName: organizationName,
    options: options,
    packages: [
        DomainLayer.packages
    ].flatMap({ $0 }),
    settings: .settings(configurations: ConfigurationInfo.default),
    targets: [
        DomainLayer.target,
        DomainLayer.test
    ],
    schemes: DomainLayer.schemes,
    fileHeaderTemplate: nil,
    additionalFiles: [],
    resourceSynthesizers: []
)
