
final class RecordingUsecaseConcrete: Sendable {
    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

extension RecordingUsecaseConcrete {

    struct Dependency: Sendable {
        let recorderService: RecorderServiceInterface
        let recordFileRepository: RecordFileRepository
        let conversationRepository: ConversationRepository
    }

}

extension RecordingUsecaseConcrete: RecordingUsecase {

}
