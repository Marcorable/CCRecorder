import SwiftUI

struct PlayTab: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentTime: TimeInterval = .zero
    @State private var duration: TimeInterval = .zero
    
    var body: some View {
        VStack(alignment: .center) {
            Slider(
                value: $currentTime,
                in: .zero...duration,
                onEditingChanged: onEditingChanged(_:)
            )
            .padding(.horizontal)
            HStack(alignment: .top) {
                Text(currentTime.displayTime)
                Spacer()
                Text(duration.displayTime)
            }
            .padding([.leading, .trailing])
            .foregroundColor(.gray)
            .font(.caption)
            .overlay {
                // if disabledPlaying { FIXME: Player 메서드
                    Text("녹음 파일 없음")
                        .font(.headline)
                // }
            }
            HStack(alignment: .center) {
                SpeedMenu()
                PlayTool()
                PinButton()
            }
        }
        .background(colorScheme == .dark ? Color.Dark.background : Color.Light.background)
        .onAppear {
            // setup()
        }
        .onDisappear {
            // finish()
        }
    }
    
}

private extension PlayTab {
    
    // var disabledPlaying: Bool { duration == .zero }
    
    func onEditingChanged(_ isEditing: Bool) {
        
    }
        
}

#Preview {
    PlayTab()
}
