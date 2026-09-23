//
//  Conversation.swift
//  CCRecorder
//
//  Created by 김용우 on 9/9/24.
//

import Foundation
import SwiftData

@Model
final class Conversation {
    #Unique<Conversation>([\.id])
    
    var id: UUID
    var createdDate: Date
    var recordFilePath: URL
    var pins: [TimeInterval]
    var title: String
    var topic: String
    @Relationship var notes: [Note]
    @Relationship var members: [Memeber]
    
    init(
        id: UUID,
        createdDate: Date = .init(),
        recordFilePath: URL,
        pins: [TimeInterval] = [],
        title: String,
        topic: String,
        notes: [Note] = [],
        members: [Memeber]
    ) {
        self.id = id
        self.createdDate = createdDate
        self.recordFilePath = recordFilePath
        self.pins = pins
        self.title = title
        self.topic = topic
        self.notes = notes
        self.members = members
    }
    
}
