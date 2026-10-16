//
//  ConversationbRepository.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/28.
//

import Common

import Combine

public protocol ConversationRepository {
    var dataSourceSubject: CurrentValueSubject<[ConversationEntity], DataError> { get }
	func fetch() -> [ConversationEntity]?
	func create(_ item: ConversationEntity, completion: (CCError?) -> Void)
	func update(after updatedItem: ConversationEntity, completion: (CCError?) -> Void)
	func delete(_ item: ConversationEntity, completion: (CCError?) -> Void)
}

#if DEBUG
struct FakeConversationRepository: ConversationRepository {
    
    var dataSourceSubject: CurrentValueSubject<[ConversationEntity], DataError> = .init([])
    func fetch() -> [ConversationEntity]? { return [] }
    func create(_ item: ConversationEntity, completion: (Common.CCError?) -> Void) {}
    func update(after updatedItem: ConversationEntity, completion: (Common.CCError?) -> Void) {}
    func delete(_ item: ConversationEntity, completion: (Common.CCError?) -> Void) {}
}
#endif
