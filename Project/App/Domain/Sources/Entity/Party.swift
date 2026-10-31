
import Foundation

public struct Party: Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public let isAvailable: Bool

    public init(
        id: UUID = .init(),
        name: String,
        isAvailable: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isAvailable = isAvailable
    }

}
