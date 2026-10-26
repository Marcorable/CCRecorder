
import Foundation

public protocol PartyRepository: Sendable {
    func create(_ party: Party) async throws
    func read() async throws -> [Party]
    func update(_ party: Party) async throws
    func delete(ids: [UUID]) async throws
}
