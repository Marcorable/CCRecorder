
final class RecordingUsecaseConcrete: Sendable {
    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

extension RecordingUsecaseConcrete {

    struct Dependency: Sendable {
        let recorderService: RecorderService
        let recordFileRepository: RecordFileRepository
        let conversationRepository: ConversationRepository
    }

}

extension RecordingUsecaseConcrete: RecordingUsecase {

}
