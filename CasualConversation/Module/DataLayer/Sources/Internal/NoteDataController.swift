//
//  NoteDataController.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/07/03.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Domain

import CoreData
import UIKit

extension NoteEntity {
	
	init(entity: NSManagedObject) {
		self.init(
			id: entity.value(forKey: "id") as! Identifier,
			original: entity.value(forKey: "original") as! String,
			translation: entity.value(forKey: "translation") as! String,
			category: NoteCategory(rawValue: entity.value(forKey: "category") as! String)!,
			references: entity.value(forKey: "references") as! [Identifier],
			createdDate: entity.value(forKey: "createdDate") as! Date
		)
	}
	
	func setValues(_ entity: NSManagedObject) {
		entity.setValue(id, forKey: "id")
		entity.setValue(original, forKey: "original")
		entity.setValue(translation, forKey: "translation")
		entity.setValue(category.rawValue, forKey: "category")
		entity.setValue(references, forKey: "references")
		entity.setValue(createdDate, forKey: "createdDate")
	}
}

final class NoteDataController {
	
	static let entityName = "NoteEntity"
	
    struct Dependency {
        let coreDataStack: CoreDataStack
    }
	private let dependency: Dependency
	
	init(dependency: Dependency) {
		self.dependency = dependency
	}
	
}

// MARK: - Usa CoreDataRepository
extension NoteDataController: NoteRepository {
	
	func fetch() -> [NoteEntity]? {
		let fetchRequest = NoteData.fetchRequest()
		let sortDescriptor = NSSortDescriptor.init(
			key: #keyPath(NoteData.createdDate),
			ascending: false
		)
		fetchRequest.sortDescriptors = [sortDescriptor]
		do {
			let list = try dependency.coreDataStack
				.mainContext.fetch(fetchRequest)
				.compactMap({ NoteEntity(entity: $0) })
			return list
		} catch {
			CCError.log.append(.persistenceFailed(reason: .coreDataUnloaded(error)))
			return nil
		}
	}
	
	func create(_ item: NoteEntity, completion: (CCError?) -> Void) {
		let entity = NoteData(context: dependency.coreDataStack.mainContext)
		item.setValues(entity)
		self.dependency.coreDataStack.saveContext(completion: completion)
		completion(nil)
	}
	
	func update(after editedItem: NoteEntity, completion: (CCError?) -> Void) {
		do {
			let objects = try dependency.coreDataStack.mainContext.fetch(NoteData.fetchRequest())
			guard let object = objects.first(where: { $0.id == editedItem.id }) else {
				completion(.persistenceFailed(reason: .coreDataUnloadedEntity))
				return
			}
			editedItem.setValues(object)
			self.dependency.coreDataStack.saveContext(completion: completion)
			completion(nil)
		} catch let error {
			completion(.persistenceFailed(reason: .coreDataUnloaded(error)))
		}
	}
	
	func delete(_ item: NoteEntity, completion: (CCError?) -> Void) {
		do {
			let objects = try dependency.coreDataStack.mainContext.fetch(NoteData.fetchRequest())
			guard let object = objects.first(where: { $0.id == item.id }) else {
				completion(.persistenceFailed(reason: .coreDataUnloadedEntity))
				return
			}
			self.dependency.coreDataStack.mainContext.delete(object)
			self.dependency.coreDataStack.saveContext(completion: completion)
			completion(nil)
		} catch let error {
			completion(.persistenceFailed(reason: .coreDataUnloaded(error)))
		}
	}
	
}
