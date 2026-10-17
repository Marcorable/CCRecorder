//
//  ConversationDataController.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/07/03.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Domain

import CoreData
import Combine

extension ConversationEntity {
    
	init(entity: NSManagedObject) {
		self.init(
			id: entity.value(forKey: "id") as! UUID,
			title: entity.value(forKey: "title") as? String,
			topic: entity.value(forKey: "topic") as? String,
			members: entity.value(forKey: "members") as! [String],
			recordFilePath: entity.value(forKey: "recordFilePath") as! URL,
			recordedDate: entity.value(forKey: "recordedDate") as! Date,
			pins: entity.value(forKey: "pins") as! [TimeInterval]
		)
	}
	
	func setValues(_ entity: NSManagedObject) {
		entity.setValue(id, forKey: "id")
		entity.setValue(title, forKey: "title")
		entity.setValue(topic, forKey: "topic")
		entity.setValue(members, forKey: "members")
		entity.setValue(recordFilePath, forKey: "recordFilePath")
		entity.setValue(recordedDate, forKey: "recordedDate")
		entity.setValue(pins, forKey: "pins")
	}
	
}

final class ConversationDataController: ConversationRepository {
    public var dataSourceSubject: CurrentValueSubject<[ConversationEntity], DataError> = .init([])
    
    struct Dependency {
        let coreDataStack: CoreDataStack
    }
    private let dependency: Dependency
	
	init(dependency: Dependency) {
		self.dependency = dependency
	}

	func fetch() -> [ConversationEntity]? {
		let fetchRequest = ConversationData.fetchRequest()
		let sortDescriptor = NSSortDescriptor.init(
			key: #keyPath(ConversationData.recordedDate),
			ascending: false
		)
		fetchRequest.sortDescriptors = [sortDescriptor]
		do {
			let list = try dependency.coreDataStack
				.mainContext.fetch(fetchRequest)
				.compactMap({ ConversationEntity(entity: $0) })
			return list
		} catch {
			CCError.log.append(.persistenceFailed(reason: .coreDataUnloaded(error)))
			return nil
		}
	}
	
	func create(_ item: ConversationEntity, completion: (CCError?) -> Void) {
		let entity = ConversationData(context: dependency.coreDataStack.mainContext)
		item.setValues(entity)
		self.dependency.coreDataStack.saveContext(completion: completion)
	}
	
	func update(after editedItem: ConversationEntity, completion: (CCError?) -> Void) {
		do {
			let objects = try dependency.coreDataStack.mainContext.fetch(ConversationData.fetchRequest())
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
	
	func delete(_ item: ConversationEntity, completion: (CCError?) -> Void) {
		do {
			let objects = try dependency.coreDataStack.mainContext.fetch(ConversationData.fetchRequest())
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
