
import SwiftData

struct ConversationDeletionService {
    private let fileStore: RecordFileStore

    init(fileStore: RecordFileStore = .init()) {
        self.fileStore = fileStore
    }
}

extension ConversationDeletionService {

    @MainActor
    func delete(
        _ conversation: Conversation,
        from modelContext: ModelContext
    ) throws {
        do {
            try fileStore.removeFile(at: conversation.recordFilePath)
        } catch RecordFileStore.StoreError.fileNotFound {
        }

        modelContext.delete(conversation)
    }

}
