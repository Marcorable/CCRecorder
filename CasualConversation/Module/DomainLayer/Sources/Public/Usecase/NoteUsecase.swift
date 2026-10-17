//
//  NoteUsecase.swift
//  DomainLayer
//
//  Created by 김용우 on 3/10/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Common

import Combine

public protocol NoteUsecase {
    var noteSubject: CurrentValueSubject<[NoteEntity], Never> { get }
    
    func add(item: NoteEntity, completion: (CCError?) -> Void)
    func edit(_ newItem: NoteEntity, completion: (CCError?) -> Void)
    func delete(item: NoteEntity, completion: (CCError?) -> Void)
}
