import ProjectDescription

/// Project helpers are functions that simplify the way you define your project.
/// Share code to create targets, settings, dependencies,
/// Create your own conventions, e.g: a func that makes sure all shared targets are "static frameworks"
/// See https://docs.tuist.io/guides/helpers/

public let organizationName: String = "pseapplications"
public let projectName: String = "CCRecorder"
public let options: Project.Options = .options(
    automaticSchemesOptions: .disabled,
    defaultKnownRegions: ["Base", "ko"],
    developmentRegion: "ko",
    disableBundleAccessors: true,
    disableSynthesizedResourceAccessors: true
)
