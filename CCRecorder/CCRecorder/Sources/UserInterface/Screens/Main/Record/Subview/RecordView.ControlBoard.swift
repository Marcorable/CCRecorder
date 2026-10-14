
import SwiftUI

extension RecordView {

    struct ControlBoard: View {
        let recorder: AudioRecorder
        @Binding var isPresentedConfirmStop: Bool

        var body: some View {
            HStack(alignment: .center) {
                StopButton(
                    isEnabled: recorder.currentTime > 0,
                    action: { isPresentedConfirmStop.toggle() }
                )
                Spacer()
                RecordButton(
                    isRecording: recorder.isRecording,
                    action: toggleRecording
                )
                Spacer()
                PinButton(
                    isEnabled: recorder.isRecording,
                    action: recorder.addPin
                )
            }
        }
    }

}

private extension RecordView.ControlBoard {

    func toggleRecording() {
        if recorder.isRecording {
            recorder.pause()
        } else {
            recorder.start()
        }
    }

}

extension RecordView.ControlBoard {

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
                                ? Color.Light.logoBlue
                                : Color.Dark.logoBlue
                        )
                        .font(.system(size: 34))
                        .shadow(
                            color: .Dark.logoBlue,
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
                                    .foregroundStyle(Color.Dark.logoRed)
                                    .font(.system(size: 58))
                                Image(systemName: "pause.fill")
                                    .foregroundStyle(Color.Light.logoRed)
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
                                .foregroundStyle(Color.Light.logoRed)
                                .font(.system(size: 58))
                                .shadow(
                                    color: .Dark.logoBlue,
                                    radius: 1,
                                    x: 1,
                                    y: 1
                                )
                        }
                    }
                }
            )
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
                                ? Color.Light.logoBlue
                                : Color.Dark.logoBlue
                        )
                        .font(.system(size: 26))
                        .shadow(
                            color: .Dark.logoBlue,
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

#Preview {
    Color.Dark.recorder.overlay {
        RecordView.ControlBoard(
            recorder: .init(),
            isPresentedConfirmStop: .constant(false)
        )
        .padding()
    }
}
