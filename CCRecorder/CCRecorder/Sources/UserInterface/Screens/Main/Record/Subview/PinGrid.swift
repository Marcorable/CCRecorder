import SwiftUI

struct PinGrid: View {
    @Binding var pins: [TimeInterval]
    let isRecording: Bool
    let currentTime: TimeInterval
    
    var body: some View {
        ScrollView {
            Spacer()
            VStack {
                Spacer(minLength: 30)
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
                Spacer()
                List {
                    ForEach(pins.indices, id: \.self) { index in
                        HStack {
                            Text("📌 \(pins[index].displayTime)")
                            Spacer()
                            Button(
                                action: {
                                    withAnimation {
                                        delete(of: index)
                                    }
                                }, label: {
                                    Image(systemName: "delete.backward")
                                        .foregroundStyle(Color.Light.logoRed)
                                }
                            )
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .padding()
                .listStyle(.plain)
                .background(Color.clear)
            }
            Spacer()
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
    
    func delete(of index: Int) {
        pins.remove(at: index)
    }
  
}

#Preview {
    PinGrid(
        pins: .constant([3.0, 2.1]),
        isRecording: true,
        currentTime: .init()
    )
}
