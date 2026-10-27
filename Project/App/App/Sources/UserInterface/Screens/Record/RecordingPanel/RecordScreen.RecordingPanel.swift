
import SwiftUI

import ComposableArchitecture

extension RecordScreen {

    struct RecordingPanel: View {
        let store: StoreOf<Root.Feature>

        var body: some View {
            HStack(alignment: .center) {
                StopButton(
                    isEnabled: store.isAbleToSave,
                    action: { store.send(.view(.requestSaveButtonTapped)) }
                )
                Spacer()
                RecordButton(
                    isEnabled: store.isAbleToToggleRecording,
                    isRecording: store.isRecording,
                    action: { store.send(.view(.toggleRecordingButtonTapped)) }
                )
                Spacer()
                PinButton(
                    isEnabled: store.isRecording,
                    action: { store.send(.view(.addPinButtonTapped)) }
                )
            }
        }
    }

}

extension RecordScreen.RecordingPanel {

    struct StopButton: View {
        let isEnabled: Bool
        let action: () -> Void

        var body: some View {
            Button(
                action: action,
                label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(
                            isEnabled
                                ? Color.Logo.Prominent.blue
                                : Color.Logo.Muted.blue
                        )
                        .font(.system(size: 34))
                        .shadow(
                            color: .Logo.Muted.blue,
                            radius: 1,
                            x: 2,
                            y: 2
                        )
                        .frame(maxWidth: .infinity)
                }
            )
            .disabled(!isEnabled)
        }
    }

    struct RecordButton: View {
        let isEnabled: Bool
        let isRecording: Bool
        let action: () -> Void

        var body: some View {
            Button(
                action: action,
                label: {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 2)
                            .frame(
                                width: 66,
                                height: 66
                            )
                            .foregroundStyle(.white)
                        if isRecording {
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(Color.Logo.Muted.red)
                                    .font(.system(size: 58))
                                Image(systemName: "pause.fill")
                                    .foregroundStyle(Color.Logo.Prominent.red)
                                    .font(.system(size: 34))
                            }
                            .shadow(
                                color: .black,
                                radius: 1,
                                x: 1,
                                y: 1
                            )
                        } else {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(Color.Logo.Prominent.red)
                                .font(.system(size: 58))
                                .shadow(
                                    color: .Logo.Muted.blue,
                                    radius: 1,
                                    x: 1,
                                    y: 1
                                )
                        }
                    }
                }
            )
            .disabled(!isEnabled)
        }
    }

    struct PinButton: View {
        let isEnabled: Bool
        let action: () -> Void

        var body: some View {
            Button(
                action: action,
                label: {
                    Image(systemName: "pin")
                        .foregroundStyle(
                            isEnabled
                                ? Color.Logo.Prominent.blue
                                : Color.Logo.Muted.blue
                        )
                        .font(.system(size: 26))
                        .shadow(
                            color: .Logo.Muted.blue,
                            radius: 1,
                            x: 2,
                            y: 2
                        )
                        .frame(maxWidth: .infinity)
                }
            )
            .disabled(!isEnabled)
        }
    }

}

#if DEBUG
#Preview {
    Color.Surface.Recorder.muted.overlay {
        RecordScreen.RecordingPanel(
            store: .init(
                initialState: .init(
                    phase: .recording,
                    currentTime: 3
                ),
                reducer: { RecordScreen.Root.Feature() },
                withDependencies: {
                    $0.recordUsecase = .live(
                        service: MockRecorderService(
                            isRecording: true,
                            currentTime: 3
                        )
                    )
                }
            )
        )
        .padding()
    }
}
#endif
