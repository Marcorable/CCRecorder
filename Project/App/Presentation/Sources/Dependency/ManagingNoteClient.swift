
import Foundation

import Domain
import ComposableArchitecture

@DependencyClient
struct ManagingNoteClient: Sendable {
    var loadNotes: @Sendable () async -> Result<[Note], DomainError> = { .success([]) }
    var updateNote: @Sendable (Note) async -> Result<Void, DomainError> = { _ in .success(()) }
    var deleteNotes: @Sendable ([UUID]) async -> Result<Void, DomainError> = { _ in .success(()) }
}

extension ManagingNoteClient {

    init(usecase: ManagingNoteUsecase) {
        self.init(
            loadNotes: { await usecase.loadNotes() },
            updateNote: { await usecase.updateNote($0) },
            deleteNotes: { await usecase.deleteNotes(ids: $0) }
        )
    }

}

extension ManagingNoteClient: TestDependencyKey {

    static let previewValue = Self(usecase: FakeManagingNoteUsecase())
    static let testValue = Self()

}

extension DependencyValues {

    var managingNoteUsecase: ManagingNoteClient {
        get { self[ManagingNoteClient.self] }
        set { self[ManagingNoteClient.self] = newValue }
    }

}
