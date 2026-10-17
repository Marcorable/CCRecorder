//
//  Note.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/25.
//

import Common

import Foundation.NSDate

public enum NoteCategory: String {
    case vocabulary
    case sentence
}

public protocol Note: UUIDIdentifiable{
    associatedtype Category
    
    var id: Identifier { get }
    var original: String { get }
    var translation: String { get }
    var category: Category { get }
    var references: [Identifier] { get }
    var createdDate: Date { get }
}

public struct NoteEntity: Note {
	
	public static var empty: Self {
		.init(
			id: UUID(),
			original: "",
			translation: "",
			category: .vocabulary,
			references: [],
			createdDate: Date()
		)
	}
    
	public let id: Identifier
	public let original: String
	public let translation: String
	public let category: NoteCategory
	public let references: [Identifier]
	public let createdDate: Date
	
	public init(
		id: Identifier,
		original: String,
		translation: String,
		category: NoteCategory,
		references: [Identifier],
		createdDate: Date
	) {
		self.id = id
		self.original = original
		self.translation = translation
		self.category = category
		self.references = references
		self.createdDate = createdDate
	}
	
	public var isDone: Bool {
		!self.original.isEmpty && !self.translation.isEmpty
	}
    
}
