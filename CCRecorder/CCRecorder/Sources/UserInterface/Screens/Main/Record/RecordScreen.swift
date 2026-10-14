
enum RecordScreen {

    enum Intent: Hashable {
        case prepare
        case toggleRecording
        case addPin
        case removePin(_ index: Int)
        case requestCancel
        case requestSave
        case cancel
        case save
        case dismissAlert
    }

    enum Status: Hashable, Error {
        case idle
        case alert(Alert)

        enum Alert: Hashable {
            case confirmCancel
            case confirmSave
            case permissionDenied
            case prepareFailed
        }
    }

}
