
import SwiftData

import Domain

public enum DataFactory {
    private static var modelContainer: ModelContainer!
}

extension DataFactory {

    public static func setup(
        _ isStoredInMemoryOnly: Bool
    ) throws {
        self.modelContainer = try ModelContainer(
            for: Note.Record.self,
            Conversation.Record.self,
            Party.Record.self,
            configurations: .init(
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
        )
    }

}

extension DataFactory {

    public static func makeRecordFileRepository() -> RecordFileRepository {
        RecordFileRepositoryConcrete()
    }

    public static func makeNoteRepository() -> NoteRepository {
        NoteRepositoryConcrete(modelContainer: modelContainer)
    }

    public static func makeConversationRepository() -> ConversationRepository {
        ConversationRepositoryConcrete(modelContainer: modelContainer)
    }

    public static func makePartyRepository() -> PartyRepository {
        PartyRepositoryConcrete(modelContainer: modelContainer)
    }

}
