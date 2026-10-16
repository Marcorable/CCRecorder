//
//  Scheme.swift
//  AniLanguageAppManifests
//
//  Created by 김용우 on 2023/10/25.
//

import ProjectDescription

public extension Scheme {
    
    static func make(
        name: String,
        for configuration: ConfigurationName,
        arguments: Arguments? = .arguments(environmentVariables: ["OS_ACTIVITY_MODE": "disable"]),
        diagnosticsOptions: SchemeDiagnosticsOptions = .options(mainThreadCheckerEnabled: true, performanceAntipatternCheckerEnabled: true),
        targets: [TargetReference] = []
    ) -> Scheme {
        .scheme(
            name: "\(name) [\(configuration.description)]",
            buildAction: .buildAction(targets: targets),
            testAction: .testPlans([], configuration: configuration),
            runAction: .runAction(
                configuration: configuration,
                executable: targets.first,
                arguments: arguments,
                diagnosticsOptions: diagnosticsOptions
            ),
            archiveAction: .archiveAction(configuration: configuration),
            profileAction: .profileAction(configuration: configuration),
            analyzeAction: .analyzeAction(configuration: configuration)
        )
    }
    
}
