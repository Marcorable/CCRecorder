
extension DomainError {

    public enum RecordingUsecaseFailure: Error, Equatable, Sendable {
        case prepareFailed
        case finishFailed
        case saveFailed
    }

}
