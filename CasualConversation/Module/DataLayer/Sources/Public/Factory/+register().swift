//
//  +register().swift
//  Data
//
//  Created by 김용우 on 6/2/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common
import Domain

import Foundation

extension DataFactory {
    
    public static func register(_ container: DependencyContainer) {
        container.register(
            CoreDataStack.self,
            inObjectScope: .container
        ) { _ in
            CoreDataStack()
        }
        
        container.register(
            ConversationRepository.self,
            inObjectScope: .container
        ) { resolver in
            ConversationDataController(
                dependency: .init(
                    coreDataStack: resolver.resolve(CoreDataStack.self)!
                )
            )
        }
        
        container.register(
            NoteRepository.self,
            inObjectScope: .container
        ) { resolver in
            NoteDataController(
                dependency: .init(
                    coreDataStack: resolver.resolve(CoreDataStack.self)!
                )
            )
        }
        
        container.register(RecordRepository.self) { resolver in
            RecordDataController(
                dependency: .init(
                    documentURL: FileManager.default.urls(
                        for: .documentDirectory,
                        in: .userDomainMask
                    )[0]
                )
            )
        }
    }
    
}
