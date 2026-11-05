
import SwiftUI

extension ConversationDetailScreen.PlaybackPanel {

    struct PlayTool: View {

        enum Direction {
            case back
            case forward
        }

        let isPlaying: Bool
        let disabled: Bool
        let skipTime: Int
        let play: () -> Void
        let pause: () -> Void
        let skip: (Direction) -> Void

        var body: some View {
            Group {
                Button(
                    action: { skip(.back) },
                    label: {
                        Spacer()
                        Image(systemName: "gobackward.\(skipTime)")
                            .font(.system(size: 22))
                        Spacer()
                    }
                )
                Button(
                    action: isPlaying ? pause : play,
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
                        Image(systemName: "goforward.\(skipTime)")
                            .font(.system(size: 22))
                        Spacer()
                    }
                )
            }
            .foregroundStyle(Color(asset: Asset.Logo.Prominent.blue))
            .disabled(disabled)
            .opacity(disabled ? 0.3 : 1)
        }
    }

}

private extension ConversationDetailScreen.PlaybackPanel.PlayTool {

    var playButtonImageName: String {
        if disabled {
            "speaker.slash.circle.fill"
        } else {
            isPlaying ? "pause.circle.fill" : "play.circle.fill"
        }
    }

}

#Preview("Playing") {
    HStack {
        ConversationDetailScreen.PlaybackPanel.PlayTool(
            isPlaying: true,
            disabled: false,
            skipTime: 5,
            play: {},
            pause: {},
            skip: { _ in }
        )
    }
    .padding()
}

#Preview("Disabled") {
    HStack {
        ConversationDetailScreen.PlaybackPanel.PlayTool(
            isPlaying: false,
            disabled: true,
            skipTime: 5,
            play: {},
            pause: {},
            skip: { _ in }
        )
    }
    .padding()
}
