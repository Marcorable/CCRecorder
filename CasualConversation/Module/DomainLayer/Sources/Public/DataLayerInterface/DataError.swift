//
//  DataError.swift
//  DomainLayer
//
//  Created by 김용우 on 3/10/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Foundation

public enum DataError: Error, CustomDebugStringConvertible {
    case fetchFailure(Entity)
    
    public var debugDescription: String {
        switch self {
            case .fetchFailure(let entity):     return "\(entity) 불러오기 실패"
        }
    }
    
    public enum Entity: CustomDebugStringConvertible {
        case conversation
        case note
        case record
        
        public var debugDescription: String {
            switch self {
                case .conversation:             return "Conversation"
                case .note:                     return "Note"
                case .record:                   return "Record"
            }
        }
    }
}
