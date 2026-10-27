
import SwiftData

import Data

@MainActor
func makeTestModelContainer() throws -> ModelContainer {
    let schema = DataFactory.setup()
    return try .init(
        for: schema,
        configurations: .init(
            schema: schema,
            isStoredInMemoryOnly: true
        )
    )
}
