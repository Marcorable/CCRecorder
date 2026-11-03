
import SwiftData

extension DataFactory {

    public struct Persistence {
        public let modelContainer: ModelContainer
        public let diagnostics: [String]
    }

}

extension DataFactory {

    @MainActor
    public static func preparePersistence() throws -> Persistence {
        let schema = setup()
        let configuration = ModelConfiguration(
            "CCRecorder",
            schema: schema,
            cloudKitDatabase: .none
        )
        let modelContainer = try ModelContainer(
            for: schema,
            configurations: configuration
        )
        let migration = LegacyStoreMigrator().migrate(
            into: modelContainer
        )
        return .init(
            modelContainer: modelContainer,
            diagnostics: migration.issues
        )
    }

}
