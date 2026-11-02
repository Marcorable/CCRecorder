
import SwiftUI

extension ConversationDetailScreen.PlaybackPanel {

    struct PlayTool: View {
        let isPlaying: Bool
        let isDisabled: Bool
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
                        Image(systemName: "goforward." + skipTime)
                            .font(.system(size: 22))
                        Spacer()
                    }
                )
            }
            .foregroundStyle(Color(asset: Asset.Logo.Prominent.blue))
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.3 : 1)
        }
    }

}

extension ConversationDetailScreen.PlaybackPanel.PlayTool {

    enum Direction {
        case back
        case forward
    }

}

private extension ConversationDetailScreen.PlaybackPanel.PlayTool {

    var skipTime: String { "\(Int(skipInterval))" }
    var playButtonImageName: String {
        if isDisabled {
            "speaker.slash.circle.fill"
        } else {
            isPlaying ? "pause.circle.fill" : "play.circle.fill"
        }
    }

}
