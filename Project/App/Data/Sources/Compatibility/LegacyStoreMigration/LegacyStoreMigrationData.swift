
import Foundation

struct LegacyStoreMigrationData {
    let conversations: [Conversation]
    let notes: [Note]
    let parties: [Party]
    let recordSource: RecordSource
}

extension LegacyStoreMigrationData {

    struct Conversation {
        let id: UUID
        let createdDate: Date
        let recordFileName: String
        let pins: [TimeInterval]
        let title: String
        let topic: String
        let noteIds: [UUID]
        let parties: [Party]
    }

    struct Note {
        let id: UUID
        let createdDate: Date
        let original: String
        let translation: String
        let category: Category

        enum Category {
            case vocabulary
            case sentence
        }
    }

    struct Party {
        let id: UUID
        let name: String
    }

    enum RecordSource {
        case currentDirectory
        case legacyDirectory(URL)
    }

}
