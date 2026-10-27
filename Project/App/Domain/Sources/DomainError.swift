
public enum DomainError: Error, Sendable {
    case data(Error)
    case recordingUsecase(RecordingUsecaseFailure)
    case playingRecordUsecase(PlayingRecordUsecaseFailure)
}
