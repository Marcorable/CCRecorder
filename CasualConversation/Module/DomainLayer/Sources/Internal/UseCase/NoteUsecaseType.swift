//
//  NoteUsecaseType.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/23.
//

import Common

import Combine

final class NoteUsecaseType: NoteUsecase {
    
    public var noteSubject: CurrentValueSubject<[NoteEntity], Never> = .init([])
    
    enum Filter {
        case all
        case selected(ConversationEntity)
    }
    
    struct Dependecy {
        let dataController: NoteRepository
        var filter: Filter
    }
    private let dependency: Dependecy
    
    init(dependency: Dependecy) {
        self.dependency = dependency
        fetchDataSource()
    }
    
    public func add(item: NoteEntity, completion: (CCError?) -> Void) {
        self.dependency.dataController.create(item) { error in
            guard error == nil else {
                completion(error)
                return
            }
            fetchDataSource()
            completion(nil)
        }
    }
    
    public func edit(_ newItem: NoteEntity, completion: (CCError?) -> Void) {
        self.dependency.dataController.update(after: newItem) { error in
            guard error == nil else {
                completion(error)
                return
            }
            fetchDataSource()
            completion(nil)
        }
    }
    
    public func delete(item: NoteEntity, completion: (CCError?) -> Void) {
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
extension NoteUsecaseType {
    
    private func fetchDataSource() {
        let fetcedList: [NoteEntity]
        switch dependency.filter {
            case .all:
                fetcedList = dependency.dataController.fetch() ?? []
            case .selected(_):
                fetcedList = dependency.dataController.fetch() ?? []
        }
        self.noteSubject.send(fetcedList.filter({ !$0.isDone }) + fetcedList.filter({ $0.isDone }))
    }
    
}
