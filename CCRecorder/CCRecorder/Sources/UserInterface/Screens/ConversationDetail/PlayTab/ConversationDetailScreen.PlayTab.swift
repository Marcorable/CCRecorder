
import SwiftUI

extension ConversationDetailScreen {

    struct PlayTab: View {
        @AppStorage(.skipInterval) private var skipInterval: SkipInterval = .five

        let player: AudioPlayer
        let filePath: URL?
        let pins: [TimeInterval]

        @State private var isEditing: Bool = false
        @State private var editingTime: TimeInterval = .zero
        @State private var isSetupFailed: Bool = false
        @State private var isPresentedSetupFailedAlert: Bool = false

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
                    if isSetupFailed {
                        Text("재생할 수 없는 녹음 파일")
                            .font(.headline)
                    } else if disabledPlaying {
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
                        skipInterval: skipInterval.timeInterval,
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
            .background(Color.Surface.Background.primary)
            .onAppear(perform: setup)
            .onDisappear {
                player.finish()
            }
            .alert(
                "녹음 파일을 재생할 수 없습니다",
                isPresented: $isPresentedSetupFailedAlert,
                actions: {
                    Button("확인", role: .cancel) { }
                },
                message: {
                    Text("파일이 손상되었을 수 있습니다.")
                }
            )
        }
    }

}

private extension ConversationDetailScreen.PlayTab {

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

    var nextPin: TimeInterval? {
        guard !disabledPlaying else {
            return nil
        }
        return pins.sorted().first { $0 > displayedTime }
    }

    func setup() {
        guard let filePath, RecordFileStore().fileExists(at: filePath) else {
            return
        }

        do {
            try player.setup(filePath: filePath)
            isSetupFailed = false
        } catch {
            isSetupFailed = true
            isPresentedSetupFailedAlert = true
        }
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
                player.seek(to: player.currentTime - skipInterval.timeInterval)

            case .forward:
                player.seek(to: player.currentTime + skipInterval.timeInterval)
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
    ConversationDetailScreen.PlayTab(
        player: .init(),
        filePath: .init(filePath: "/dev/null"),
        pins: [3.0, 8.5]
    )
}
