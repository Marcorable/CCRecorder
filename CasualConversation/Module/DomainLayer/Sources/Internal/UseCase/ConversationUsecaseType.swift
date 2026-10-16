//
//  ConversationUsecaseType.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/28.
//

import Common

//import Foundation.NSURL
import Combine

public final class ConversationUsecaseType: ConversationUsecase {
	
    public var conversationSubejct: CurrentValueSubject<[ConversationEntity], Never> = .init([])
    
    struct Dependency {
		let dataController: ConversationRepository
	}
    private let dependency: Dependency
	
    init(dependency: Dependency) {
		self.dependency = dependency
		
        fetchDataSource()
	}
 
}

extension ConversationUsecaseType { // MARK: - ConversationRecodable
	
    public func add(_ item: ConversationEntity, completion: (CCError?) -> Void) {
		self.dependency.dataController.create(item) { error in
			guard error == nil else {
				completion(error)
				return
			}
			fetchDataSource()
			completion(nil)
		}
	}
	
}

extension ConversationUsecaseType { // MARK: - ConversationMaintainable
	
    public func edit(after editedItem: ConversationEntity, completion: (CCError?) -> Void) {
		self.dependency.dataController.update(after: editedItem) { error in
			guard error == nil else {
				completion(error)
				return
			}
			fetchDataSource()
			completion(nil)
		}
	}
	
    public func delete(_ item: ConversationEntity, completion: (CCError?) -> Void) {
		self.dependency.dataController.delete(item) { error in
			guard error == nil else {
				completion(error)
				return
			}
			fetchDataSource()
			completion(nil)
		}
	}
	
}

// MARK: - Private Methods
extension ConversationUsecaseType {
    
    private func fetchDataSource() {
        guard let fetcedList = dependency.dataController.fetch() else {
            CCError.log.append(.log("Failure fetchDataSource"))
            return
        }
        self.conversationSubejct.send(fetcedList)
    }
    
}
