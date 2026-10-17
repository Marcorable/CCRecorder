//
//  DataFactory.swift
//  DomainLayer
//
//  Created by 김용우 on 3/10/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Domain

import Foundation

public enum DataFactory {
    
    // FIXME: 삭제 예정
    private static let coreDataStack: CoreDataStack = .init()
    public static func makeConversationRepository() -> ConversationRepository {
        ConversationDataController(
            dependency: .init(
                coreDataStack: Self.coreDataStack
            )
        )
    }
    public static func makeNoteRepository() -> NoteRepository {
        NoteDataController(
            dependency: .init(
                coreDataStack: Self.coreDataStack
            )
        )
    }
    public static func makeRecordRepository(of documentURL: URL) -> RecordRepository {
        RecordDataController(
            dependency: .init(documentURL: documentURL)
        )
    }
}
