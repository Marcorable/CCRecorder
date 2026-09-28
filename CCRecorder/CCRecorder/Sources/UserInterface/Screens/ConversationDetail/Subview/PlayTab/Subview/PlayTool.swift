import SwiftUI

struct PlayTool: View {
    @State private var isPlaying: Bool = false
    
    let disabledPlaying: Bool = false // FIXME: Player 메서드
    
    var body: some View {
        Group {
            Button(
                action: { }, // skip(.back) },
                label: {
                    Spacer()
                    Image(systemName: "gobackward." + "skipTime")
                        .font(.system(size: 22))
                    Spacer()
                }
            )
            Button(
                action: {
                    if isPlaying {
                        // pause()
                    } else {
                        // start()
                    }
                }, label: {
                    Spacer()
                    Image(systemName: playButtonImageName)
                        .font(.system(size: 44))
                    Spacer()
                }
            )
            Button(
                action: { }, // skip(.forward)
                label: {
                    Spacer()
                    Image(systemName: "goforward." + "skipTime")
                        .font(.system(size: 22))
                    Spacer()
                }
            )
        }
        .foregroundStyle(Color.Light.logoBlue)
        .disabled(disabledPlaying)
        .opacity(disabledPlaying ? 0.3 : 1.0)
    }
}

private extension PlayTool {
    
    var playButtonImageName: String {
        if disabledPlaying {
            return "speaker.slash.circle.fill"
        } else {
            return isPlaying ? "pause.circle.fill" : "play.circle.fill"
        }
    }
    
}
