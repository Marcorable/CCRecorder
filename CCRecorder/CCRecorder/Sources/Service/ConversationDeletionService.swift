
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
        if let recordFileURL = fileStore.fileURL(of: conversation.recordFileName) {
            do {
                try fileStore.removeFile(at: recordFileURL)
            } catch RecordFileStore.StoreError.fileNotFound {
            }
        }

        modelContext.delete(conversation)
    }

}
