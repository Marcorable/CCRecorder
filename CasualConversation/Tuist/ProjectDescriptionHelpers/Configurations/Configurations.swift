//
//  Configurations.swift
//  ProjectDescriptionHelpers
//
//  Created by 김용우 on 2023/10/25.
//

import ProjectDescription

extension ConfigurationName: CustomStringConvertible {
    static let sandboxDebug: Self = .configuration("SandboxDebug")
    static let sandboxRelease: Self = .configuration("SandboxRelease")
    static let productDebug: Self = .configuration("ProductDebug")
    static let productRelease: Self = .configuration("ProductRelease")
    
    public var description: String {
        switch self {
            case .sandboxDebug:         return "SANDBOX DEBUG"
            case .sandboxRelease:       return "SANDBOX RELEASE"
            case .productDebug:         return "PRODUCT DEBUG"
            case .productRelease:       fallthrough
            default:                    return "PRODUCT RELEASE"
        }
    }
    
    var rawValue: String {
        switch self {
            case .sandboxDebug:         return "sandboxDebug"
            case .sandboxRelease:       return "sandboxRelease"
            case .productDebug:         return "productDebug"
            case .productRelease:       fallthrough
            default:                    return "productRelease"
        }
    }
    
}

public struct ConfigurationInfo {
    
    public static let `default`: [Configuration] = [
        .debug(name: .sandboxDebug,         settings: ConfigurationInfo(.sandboxDebug).settings),
        .release(name: .sandboxRelease,     settings: ConfigurationInfo(.sandboxRelease).settings),
        .debug(name: .productDebug,         settings: ConfigurationInfo(.productDebug).settings),
        .release(name: .productRelease,     settings: ConfigurationInfo(.productRelease).settings)
    ]
        
    private let configurationName: ConfigurationName
    
    init(_ configurationName: ConfigurationName) {
        self.configurationName = configurationName
    }
    
    public var settings: SettingsDictionary {
        SettingsDictionary()
            .merging(APP_BUNDLE_ID_POST_FIX)
            .merging(SWIFT_ACTIVE_COMPILATION_CONDITIONS)
            .merging(DEVELOPMENT_TEAM)
            .merging(DEBUG_INFORMATION_FORMAT)
    }
    
    private var APP_BUNDLE_ID_POST_FIX: SettingsDictionary {
        ["\(#function)": "\(configurationName.rawValue)"]
    }
    
    private var SWIFT_ACTIVE_COMPILATION_CONDITIONS: SettingsDictionary {
        ["\(#function)": "\(configurationName.description)"]
    }
    
    private var DEVELOPMENT_TEAM: SettingsDictionary {
        ["\(#function)": "9486RJPBM5"]
    }
    
    private var DEBUG_INFORMATION_FORMAT: SettingsDictionary {
        ["\(#function)": "DWARF with dSYM File"]
    }
}
