import SwiftUI

struct SpeedMenu: View {
    let speed: Speed
    let select: (Speed) -> Void

    var body: some View {
        Menu(
            content: {
                ForEach(Speed.allCases, id: \.self) { speed in
                    Button(
                        action: { select(speed) },
                        label: {
                            Text(speedDescription(of: speed))
                                .foregroundStyle(Color.Dark.logoBlue)
                                .font(.caption)
                        }
                    )
                }
            }, label: {
                Spacer()
                Text(speedDescription(of: speed))
                    .foregroundStyle(Color.Dark.logoBlue)
                    .font(.headline)
                Spacer()
            }
        )
    }
    
}

extension SpeedMenu {
    
    private func speedDescription(of speed: Speed) -> String {
        let format: String
        switch speed {
        case .half, .default, .oneAndHalf, .double:
            format = "%.1fx"
        default:
            format = "%.2fx"
        }
        return .init(format: format, speed.rawValue)
    }
    
}
