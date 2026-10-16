//
//  NoteRepository.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/28.
//

import Common

public protocol NoteRepository {
	func fetch() -> [NoteEntity]?
	func create(_ item: NoteEntity, completion: (CCError?) -> Void)
	func update(after updatedItem: NoteEntity, completion: (CCError?) -> Void)
	func delete(_ item: NoteEntity, completion: (CCError?) -> Void)
}
