//
//  +register().swift
//  Domain
//
//  Created by 김용우 on 6/2/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common

extension DomainFactory {
    
    public static func register(_ container: DependencyContainer) {
        container.register(ConversationUsecase.self) { resolver in
            ConversationUsecaseType(
                dependency: .init(
                    dataController: resolver.resolve(ConversationRepository.self)!
                )
            )
        }

        container.register(NoteUsecase.self, name: "all") { resolver in
            NoteUsecaseType(
                dependency: .init(
                    dataController: resolver.resolve(NoteRepository.self)!,
                    filter: .all
                )
            )
        }
        
        container.register(CCRecorder.self) { resolver in
            AudioRecordService(
                dependency: .init(
                    dataController: resolver.resolve(RecordRepository.self)!
                )
            )
        }
        
        container.register(CCPlayer.self) { resolver in
            AudioPlayService(
                dependency: .init(
                    dataController: resolver.resolve(RecordRepository.self)!
                )
            )
        }
    }
    
}
