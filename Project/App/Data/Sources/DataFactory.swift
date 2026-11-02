
import SwiftData

import Domain

public enum DataFactory {
    @MainActor private weak static var conversationRepository: ConversationRepositoryConcrete?
    @MainActor private weak static var noteRepository: NoteRepositoryConcrete?
    @MainActor private weak static var partyRepository: PartyRepositoryConcrete?
}

extension DataFactory {

    public static func setup() -> Schema {
        .init(
            [
                Note.Record.self,
                Conversation.Record.self,
                Party.Record.self
            ]
        )
    }

}

extension DataFactory {

    public static func recordFileRepository() -> RecordFileRepository {
        RecordFileRepositoryConcrete(
            fileManager: .default,
            baseURL: nil
        )
    }

    @MainActor
    public static func noteRepository(
        modelContainer: ModelContainer
    ) -> NoteRepository {
        if let repository = noteRepository {
            return repository
        } else {
            let repository = NoteRepositoryConcrete(modelContainer: modelContainer)
            self.noteRepository = repository
            return repository
        }
    }

    @MainActor
    public static func conversationRepository(
        modelContainer: ModelContainer
    ) -> ConversationRepository {
        if let repository = conversationRepository {
            return repository
        } else {
            let repository = ConversationRepositoryConcrete(modelContainer: modelContainer)
            self.conversationRepository = repository
            return repository
        }
    }

    @MainActor
    public static func partyRepository(
        modelContainer: ModelContainer
    ) -> PartyRepository {
        if let repository = partyRepository {
            return repository
        } else {
            let repository = PartyRepositoryConcrete(modelContainer: modelContainer)
            self.partyRepository = repository
            return repository
        }
    }

}
