
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen {

    struct PlaybackPanel: View {
        let store: StoreOf<Feature>

        @State private var editingTime: TimeInterval = .zero
        @State private var isEditing = false

        var body: some View {
            VStack(alignment: .center) {
                Slider(
                    value: sliderTime,
                    in: .zero...max(store.duration, 0.01),
                    onEditingChanged: onEditingChanged
                )
                .padding(.horizontal)
                .disabled(isPlaybackDisabled)
                HStack(alignment: .top) {
                    Text(displayedTime, format: .playbackTime)
                    Spacer()
                    Text(store.duration, format: .playbackTime)
                }
                .padding(.horizontal)
                .foregroundStyle(.gray)
                .font(.caption)
                .overlay {
                    if isPlaybackDisabled {
                        Text("재생할 수 없음")
                            .font(.headline)
                    }
                }
                HStack(alignment: .center) {
                    SpeedMenu(
                        speed: store.speed,
                        select: { store.send(.view(.speedChanged($0))) }
                    )
                    PlayTool(
                        isPlaying: store.isPlaying,
                        isDisabled: isPlaybackDisabled,
                        skipInterval: store.skipInterval.timeInterval,
                        play: { store.send(.view(.playButtonTapped)) },
                        pause: { store.send(.view(.pauseButtonTapped)) },
                        skip: {
                            switch $0 {
                                case .back:
                                    store.send(.view(.skipBackwardTapped))

                                case .forward:
                                    store.send(.view(.skipForwardTapped))
                            }
                        }
                    )
                    PinButton(
                        isDisabled: nextPin == nil,
                        jump: { store.send(.view(.nextPinTapped)) }
                    )
                }
            }
            .background(Color(asset: Asset.Surface.Background.primary))
        }
    }

}

private extension ConversationDetailScreen.PlaybackPanel {

    var isPlaybackDisabled: Bool { !store.isPrepared }
    var displayedTime: TimeInterval {
        isEditing ? editingTime : store.currentTime
    }
    var nextPin: TimeInterval? {
        guard !isPlaybackDisabled else {
            return nil
        }
        return store.pins.sorted().first(where: { $0 > displayedTime })
    }
    var sliderTime: Binding<TimeInterval> {
        .init(
            get: { displayedTime },
            set: {
                if isEditing {
                    editingTime = $0
                } else {
                    store.send(.view(.seekChanged($0)))
                }
            }
        )
    }

    func onEditingChanged(_ isEditing: Bool) {
        if isEditing {
            editingTime = store.currentTime
        } else {
            store.send(.view(.seekChanged(editingTime)))
        }
        self.isEditing = isEditing
    }

}
