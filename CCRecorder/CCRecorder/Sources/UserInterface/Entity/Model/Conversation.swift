import Foundation
import SwiftData

@Model
final class Conversation {
    #Unique<Conversation>([\.id])
    
    var id: UUID
    var createdDate: Date
    var recordFileName: String = ""
    var pins: [TimeInterval]
    var title: String
    var topic: String
    var noteIds: [UUID]
    @Relationship var parties: [Party]
    
    init(
        id: UUID = .init(),
        createdDate: Date = .init(),
        recordFileName: String,
        pins: [TimeInterval] = [],
        title: String,
        topic: String,
        notes: [UUID] = [],
        parties: [Party]
    ) {
        self.id = id
        self.createdDate = createdDate
        self.recordFileName = recordFileName
        self.pins = pins
        self.title = title
        self.topic = topic
        self.noteIds = notes
        self.parties = parties
    }
    
}
