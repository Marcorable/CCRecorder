
import Foundation

struct PlaybackTimeFormatStyle: FormatStyle {

    func format(_ value: TimeInterval) -> String {
        let pattern: Duration.TimeFormatStyle.Pattern
        if value >= 3600 {
            pattern = .hourMinuteSecond(
                padHourToLength: 2,
                roundFractionalSeconds: .up
            )
        } else {
            pattern = .minuteSecond(
                padMinuteToLength: 2,
                roundFractionalSeconds: .up
            )
        }
        return Duration.seconds(value)
            .formatted(.time(pattern: pattern))
    }

}

extension FormatStyle where Self == PlaybackTimeFormatStyle {

    static var playbackTime: Self { .init() }

}
