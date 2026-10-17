
import SwiftUI

extension RecordScreen {

    struct ControlBoard: View {
        let viewModel: ViewModel

        var body: some View {
            HStack(alignment: .center) {
                StopButton(
                    isEnabled: viewModel.isAbleToSave,
                    action: { viewModel.reduce(by: .requestSave) }
                )
                Spacer()
                RecordButton(
                    isRecording: viewModel.isRecording,
                    action: { viewModel.reduce(by: .toggleRecording) }
                )
                Spacer()
                PinButton(
                    isEnabled: viewModel.isRecording,
                    action: { viewModel.reduce(by: .addPin) }
                )
            }
        }
    }

}

extension RecordScreen.ControlBoard {

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

#if DEBUG
#Preview {
    Color.Dark.recorder.overlay {
        RecordScreen.ControlBoard(viewModel: .mock)
        .padding()
    }
}
#endif
