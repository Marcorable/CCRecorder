
import Foundation

enum RecordScreen {

    enum Intent: Hashable {
        case prepare
        case toggleRecording
        case addPin
        case removePin(_ index: Int)
        case requestCancel
        case requestSave
        case cancel
        case save(Information)
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
            case saveFailed
        }
    }

    /// 녹음과 함께 저장할 대화 정보
    struct Information: Hashable {
        let title: String
        let topic: String
        let parties: [String]
    }

}

extension RecordScreen {

    static func defaultTitle(of date: Date) -> String {
        date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }

}
