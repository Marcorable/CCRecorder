//
//  Party.swift
//  CCRecorder
//
//  Created by 김용우 on 9/10/24.
//

import Foundation
import SwiftData

@Model
final class Party {
    #Unique<Party>([\.id])
    
    var id: UUID
    var name: String
    
    init(
        id: UUID = .init(),
        name: String
    ) {
        self.id = id
        self.name = name
    }
    
}
