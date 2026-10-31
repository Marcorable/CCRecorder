
import Foundation

import Domain
import ComposableArchitecture

@DependencyClient
struct ManagingNoteClient: Sendable {
    var loadNotes: @Sendable () async -> Result<[Note], DomainError> = { .success([]) }
    var note: @Sendable (Note.ID) async -> Result<Note?, DomainError> = { _ in .success(nil) }
    var updateNote: @Sendable (Note) async -> Result<Void, DomainError> = { _ in .success(()) }
    var deleteNotes: @Sendable ([UUID]) async -> Result<Void, DomainError> = { _ in .success(()) }
}

extension ManagingNoteClient {

    init(usecase: ManagingNoteUsecase) {
        self.init(
            loadNotes: { await usecase.loadNotes() },
            note: { await usecase.note(id: $0) },
            updateNote: { await usecase.updateNote($0) },
            deleteNotes: { await usecase.deleteNotes(ids: $0) }
        )
    }

    static let preview: Self = .init(
        loadNotes: { .success([]) },
        note: { _ in .success(nil) },
        updateNote: { _ in .success(()) },
        deleteNotes: { _ in .success(()) }
    )

}

extension DependencyValues {

    @DependencyEntry(
        previewValue: ManagingNoteClient.preview
    )
    var managingNoteUsecase: ManagingNoteClient = .init()

}
