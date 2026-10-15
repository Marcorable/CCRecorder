import SwiftUI

struct PlayTab: View {
    @Environment(\.colorScheme) var colorScheme

    let player: AudioPlayer
    let filePath: URL
    let pins: [TimeInterval]
    var skipInterval: TimeInterval = PlayTab.defaultSkipInterval

    @State private var isEditing: Bool = false
    @State private var editingTime: TimeInterval = .zero

    var body: some View {
        VStack(alignment: .center) {
            Slider(
                value: sliderTime,
                in: .zero...player.duration,
                onEditingChanged: onEditingChanged(_:)
            )
            .padding(.horizontal)
            .disabled(disabledPlaying)
            HStack(alignment: .top) {
                Text(displayedTime.displayTime)
                Spacer()
                Text(player.duration.displayTime)
            }
            .padding([.leading, .trailing])
            .foregroundColor(.gray)
            .font(.caption)
            .overlay {
                if disabledPlaying {
                    Text("녹음 파일 없음")
                        .font(.headline)
                }
            }
            HStack(alignment: .center) {
                SpeedMenu(
                    speed: Speed(rawValue: player.rate) ?? .default,
                    select: { player.changeRate(to: $0.rawValue) }
                )
                PlayTool(
                    isPlaying: player.isPlaying,
                    disabledPlaying: disabledPlaying,
                    skipInterval: skipInterval,
                    play: player.play,
                    pause: player.pause,
                    skip: skip(_:)
                )
                PinButton(
                    pinDisabled: nextPin == nil,
                    jump: jumpToNextPin
                )
            }
        }
        .background(colorScheme == .dark ? Color.Dark.background : Color.Light.background)
        .onAppear {
            try? player.setup(filePath: filePath)
        }
        .onDisappear {
            player.finish()
        }
    }

}

extension PlayTab {

    static let defaultSkipInterval: TimeInterval = 10

}

private extension PlayTab {

    var disabledPlaying: Bool { player.duration == .zero }

    var displayedTime: TimeInterval {
        isEditing ? editingTime : player.currentTime
    }

    var sliderTime: Binding<TimeInterval> {
        .init(
            get: { displayedTime },
            set: { newValue in
                if isEditing {
                    editingTime = newValue
                } else {
                    player.seek(to: newValue)
                }
            }
        )
    }

    // [AI] v1 은 currentTime 이전 핀 중 첫 번째로 이동해 다음 핀이 아니었다 — 현재 시점 이후 첫 핀으로 고쳤다
    var nextPin: TimeInterval? {
        guard !disabledPlaying else {
            return nil
        }
        return pins.sorted().first { $0 > displayedTime }
    }

    func onEditingChanged(_ isEditing: Bool) {
        if isEditing {
            editingTime = player.currentTime
            player.stopTrackingCurrentTime()
        } else {
            player.seek(to: editingTime)
        }
        self.isEditing = isEditing
    }

    func skip(_ direction: PlayTool.Direction) {
        switch direction {
            case .back:
                player.seek(to: player.currentTime - skipInterval)

            case .forward:
                player.seek(to: player.currentTime + skipInterval)
        }
    }

    func jumpToNextPin() {
        guard let nextPin else {
            return
        }
        player.seek(to: nextPin)
    }

}

#Preview {
    PlayTab(
        player: .init(),
        filePath: .init(filePath: "/dev/null"),
        pins: [3.0, 8.5]
    )
}
