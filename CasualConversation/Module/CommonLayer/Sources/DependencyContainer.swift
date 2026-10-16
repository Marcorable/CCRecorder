//
//  DependencyContainer.swift
//  Common
//
//  Created by 김용우 on 6/6/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Swinject

public final class DependencyContainer {
    
    private let container = Container()
    
    public init() {}
    
    public func resolve<T>(_ type: T.Type, name: String? = nil) -> T? {
        container.resolve(type, name: name)
    }
    
    public func register<T>(
        _ type: T.Type, 
        inObjectScope objectScope: ObjectScope = .transient,
        name: String? = nil,
        factory: @escaping (Resolver) -> T
    ) {
        container.register(type, name: name, factory: factory)
            .inObjectScope(objectScope)
    }
    
}
