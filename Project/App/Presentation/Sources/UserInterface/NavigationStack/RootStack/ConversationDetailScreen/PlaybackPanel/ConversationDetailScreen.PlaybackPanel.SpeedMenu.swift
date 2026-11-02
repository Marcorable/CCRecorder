
import SwiftUI

extension ConversationDetailScreen.PlaybackPanel {

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
                                    .foregroundStyle(Color(asset: Asset.Logo.Muted.blue))
                                    .font(.caption)
                            }
                        )
                    }
                },
                label: {
                    Spacer()
                    Text(speedDescription(of: speed))
                        .foregroundStyle(Color(asset: Asset.Logo.Muted.blue))
                        .font(.headline)
                    Spacer()
                }
            )
        }

        private func speedDescription(of speed: Speed) -> String {
            let format = switch speed {
                case .half, .default, .oneAndHalf, .double:
                    "%.1fx"

                default:
                    "%.2fx"
            }
            return .init(format: format, speed.rawValue)
        }
    }

}
