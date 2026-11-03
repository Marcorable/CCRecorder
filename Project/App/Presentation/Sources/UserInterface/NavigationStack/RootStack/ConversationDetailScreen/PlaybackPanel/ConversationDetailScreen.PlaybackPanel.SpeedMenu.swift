
import SwiftUI

extension ConversationDetailScreen.PlaybackPanel {

    enum Speed: Float, CaseIterable {
        case half = 0.5
        case threeQuarter = 0.75
        case `default` = 1
        case oneAndOneQuarter = 1.25
        case oneAndHalf = 1.5
        case oneAndThreeQuarter = 1.75
        case double = 2
    }

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
                                Text(speed.title)
                                    .foregroundStyle(Color(asset: Asset.Logo.Muted.blue))
                                    .font(.caption)
                            }
                        )
                    }
                },
                label: {
                    Spacer()
                    Text(speed.title)
                        .foregroundStyle(Color(asset: Asset.Logo.Muted.blue))
                        .font(.headline)
                    Spacer()
                }
            )
        }
    }

}

fileprivate extension ConversationDetailScreen.PlaybackPanel.Speed {

    var title: String {
        let format = switch self {
            case .half, .default, .oneAndHalf, .double:
                "%.1fx"

            default:
                "%.2fx"
        }
        return .init(
            format: format,
            rawValue
        )
    }

}
