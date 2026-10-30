
import Foundation

public enum SkipInterval: Int, CaseIterable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case thirty = 30
}

extension SkipInterval {

    public var timeInterval: TimeInterval { TimeInterval(rawValue) }

}
