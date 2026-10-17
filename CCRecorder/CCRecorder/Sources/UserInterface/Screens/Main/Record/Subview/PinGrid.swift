
import SwiftUI

struct PinGrid: View {
    let pins: [TimeInterval]
    let isRecording: Bool
    let currentTime: TimeInterval
    let delete: (Int) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HStack {
                    Spacer()
                    Image(systemName: "circle.fill")
                        .foregroundStyle(circleColor)
                        .opacity(isRecording ? Int(currentTime) % 2 == 0 ? 1.0 : 0.0 : 1.0)
                    Text(currentTime.displayTime)
                        .foregroundStyle(timeColor)
                        .font(.largeTitle)
                    Spacer()
                }
                .padding(.vertical, 30)

                ForEach(pins.indices, id: \.self) { index in
                    HStack {
                        Text("📌 \(pins[index].displayTime)")
                        Spacer()
                        Button(
                            action: {
                                withAnimation {
                                    delete(index)
                                }
                            },
                            label: {
                                Image(systemName: "delete.backward")
                                    .foregroundStyle(Color.Light.logoRed)
                            }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.horizontal)
                }
            }
        }
    }
}

private extension PinGrid {

    var circleColor: Color {
        isRecording ? .Light.logoRed : .Dark.logoRed
    }

    var timeColor: Color {
        isRecording ? .white : .gray
    }

}

#Preview {
    PinGrid(
        pins: [3.0, 2.1],
        isRecording: true,
        currentTime: .init(),
        delete: { _ in }
    )
}
