
import SwiftUI

extension ConversationDetailScreen.PlayTab {

    struct PlayTool: View {
        let isPlaying: Bool
        let disabledPlaying: Bool
        let skipInterval: TimeInterval
        let play: () -> Void
        let pause: () -> Void
        let skip: (Direction) -> Void

        var body: some View {
            Group {
                Button(
                    action: { skip(.back) },
                    label: {
                        Spacer()
                        Image(systemName: "gobackward." + skipTime)
                            .font(.system(size: 22))
                        Spacer()
                    }
                )
                Button(
                    action: {
                        if isPlaying {
                            pause()
                        } else {
                            play()
                        }
                    },
                    label: {
                        Spacer()
                        Image(systemName: playButtonImageName)
                            .font(.system(size: 44))
                        Spacer()
                    }
                )
                Button(
                    action: { skip(.forward) },
                    label: {
                        Spacer()
                        Image(systemName: "goforward." + skipTime)
                            .font(.system(size: 22))
                        Spacer()
                    }
                )
            }
            .foregroundStyle(Color.Logo.Prominent.blue)
            .disabled(disabledPlaying)
            .opacity(disabledPlaying ? 0.3 : 1.0)
        }
    }

}

extension ConversationDetailScreen.PlayTab.PlayTool {

    enum Direction {
        case back
        case forward
    }

}

private extension ConversationDetailScreen.PlayTab.PlayTool {

    var skipTime: String {
        "\(Int(skipInterval))"
    }

    var playButtonImageName: String {
        if disabledPlaying {
            return "speaker.slash.circle.fill"
        } else {
            return isPlaying ? "pause.circle.fill" : "play.circle.fill"
        }
    }

}

#Preview {
    HStack {
        ConversationDetailScreen.PlayTab.PlayTool(
            isPlaying: false,
            disabledPlaying: false,
            skipInterval: 5,
            play: {},
            pause: {},
            skip: { _ in }
        )
    }
}
