//
//  ConversationUsecase.swift
//  Domain
//
//  Created by 김용우 on 6/3/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common

import Combine

public protocol ConversationUsecase: ConversationRecodable, ConversationMaintainable { }

public protocol ConversationRecodable {
    func add(_ item: ConversationEntity, completion: (CCError?) -> Void)
}

public protocol ConversationMaintainable {
    var conversationSubejct: CurrentValueSubject<[ConversationEntity], Never> { get }
    func edit(after editedItem: ConversationEntity, completion: (CCError?) -> Void)
    func delete(_ item: ConversationEntity, completion: (CCError?) -> Void)
}
