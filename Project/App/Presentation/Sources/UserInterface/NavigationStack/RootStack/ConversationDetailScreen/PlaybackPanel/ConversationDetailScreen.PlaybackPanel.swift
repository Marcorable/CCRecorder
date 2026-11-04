
import SwiftUI

import ComposableArchitecture

extension ConversationDetailScreen {

    struct PlaybackPanel: View {
        let store: StoreOf<Feature>

        @State private var editingTime: TimeInterval = .zero
        @State private var isEditing = false

        var body: some View {
            let displayedTime = isEditing
                ? editingTime
                : store.currentTime
            let nextPin = store.isPlaybackDisabled
                ? nil
                : store.pins.sorted().first(where: { $0 > displayedTime })

            VStack(alignment: .center) {
                Slider(
                    value: .init(
                        get: { displayedTime },
                        set: {
                            if isEditing {
                                editingTime = $0
                            } else {
                                store.send(.view(.seekChanged($0)))
                            }
                        }
                    ),
                    in: .zero...max(store.duration, 0.01),
                    onEditingChanged: { isEditing in
                        if isEditing {
                            editingTime = store.currentTime
                        } else {
                            store.send(.view(.seekChanged(editingTime)))
                        }
                        self.isEditing = isEditing
                    }
                )
                .padding(.horizontal)
                .disabled(store.isPlaybackDisabled)
                HStack(alignment: .top) {
                    Text(displayedTime, format: .playbackTime)
                    Spacer()
                    Text(store.duration, format: .playbackTime)
                }
                .padding(.horizontal)
                .foregroundStyle(.gray)
                .font(.caption)
                .overlay {
                    if store.isPlaybackDisabled {
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
                        disabled: store.isPlaybackDisabled,
                        skipTime: store.skipInterval.rawValue,
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
                        disabled: nextPin == nil,
                        action: { store.send(.view(.nextPinTapped)) }
                    )
                }
            }
            .background(Color(asset: Asset.Surface.Background.primary))
        }
    }

}

extension ConversationDetailScreen.PlaybackPanel {

    struct PinButton: View {
        let disabled: Bool
        let action: () -> Void

        var body: some View {
            Button(
                action: action,
                label: {
                    Spacer()
                    Image(systemName: "forward.end.alt.fill")
                        .font(.system(size: 16))
                    Spacer()
                }
            )
            .foregroundStyle(Color(asset: Asset.Logo.Muted.blue))
            .disabled(disabled)
            .opacity(disabled ? 0.3 : 1)
        }
    }

}

#Preview("Playing") {
    VStack {
        Spacer()
        ConversationDetailScreen.PlaybackPanel(
            store: .init(
                initialState: .init(
                    isPrepared: true,
                    isPlaying: true,
                    currentTime: 82,
                    duration: 245,
                    speed: .oneAndOneQuarter,
                    pins: [30, 95, 180]
                ),
                reducer: { ConversationDetailScreen.PlaybackPanel.Feature() },
                withDependencies: {
                    $0.audioSession = .preview
                    $0.playingRecordUsecase = .preview
                }
            )
        )
    }
}

#Preview("Unavailable") {
    VStack {
        Spacer()
        ConversationDetailScreen.PlaybackPanel(
            store: .init(
                initialState: .init(),
                reducer: { ConversationDetailScreen.PlaybackPanel.Feature() },
                withDependencies: {
                    $0.audioSession = .preview
                    $0.playingRecordUsecase = .preview
                }
            )
        )
    }
}

#Preview("Pin Button") {
    HStack {
        ConversationDetailScreen.PlaybackPanel.PinButton(
            disabled: false,
            action: {}
        )
        ConversationDetailScreen.PlaybackPanel.PinButton(
            disabled: true,
            action: {}
        )
    }
    .padding()
}
