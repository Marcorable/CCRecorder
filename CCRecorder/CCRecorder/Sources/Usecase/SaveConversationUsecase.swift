
import Foundation

import ComposableArchitecture

@DependencyClient
struct SaveConversationUsecase {
    var execute: @MainActor @Sendable (_ input: Input) async throws -> Void
}

extension SaveConversationUsecase {

    struct Input: Equatable, Sendable {
        let fileURL: URL
        let createdDate: Date
        let title: String
        let topic: String
        let parties: [String]
        let pins: [TimeInterval]
    }

    enum Failure: Error, Equatable {
        case saveFailed
    }

}

extension SaveConversationUsecase: TestDependencyKey {

    static let previewValue = Self()
    static let testValue = Self()

}

extension DependencyValues {

    var saveConversationUsecase: SaveConversationUsecase {
        get { self[SaveConversationUsecase.self] }
        set { self[SaveConversationUsecase.self] = newValue }
    }

}

extension SaveConversationUsecase {

    @MainActor
    static func live(
        repository: any ConversationRepository,
        fileStore: RecordFileStore
    ) -> Self {
        .init(
            execute: { input in
                do {
                    try repository.save(
                        Conversation(
                            createdDate: input.createdDate,
                            recordFileName: input.fileURL.lastPathComponent,
                            pins: input.pins,
                            title: input.title,
                            topic: input.topic,
                            parties: input.parties.map { Party(name: $0) }
                        )
                    )
                } catch {
                    try? fileStore.removeFile(at: input.fileURL)
                    throw Failure.saveFailed
                }
            }
        )
    }

}
