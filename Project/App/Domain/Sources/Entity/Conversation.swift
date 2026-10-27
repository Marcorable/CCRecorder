
import Foundation

public struct Conversation: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let createdDate: Date
    public var recordFileName: String
    public var pins: [TimeInterval]
    public var title: String
    public var topic: String
    public var noteIds: [UUID]
    public var parties: [Party]

    public init(
        id: UUID = .init(),
        createdDate: Date,
        recordFileName: String,
        pins: [TimeInterval],
        title: String,
        topic: String,
        noteIds: [UUID] = [],
        parties: [Party]
    ) {
        self.id = id
        self.createdDate = createdDate
        self.recordFileName = recordFileName
        self.pins = pins
        self.title = title
        self.topic = topic
        self.noteIds = noteIds
        self.parties = parties
    }

}
