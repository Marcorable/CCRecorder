
import SwiftUI
import Foundation

import Domain

extension MainScreen.ConversationList {

    struct Row: View {
        let viewModel: ViewModel

        var body: some View {
            HStack {
                Image(systemName: "recordingtape")
                    .foregroundStyle(Color(asset: Asset.Logo.Prominent.red))
                VStack(alignment: .leading) {
                    Text(viewModel.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    HStack(alignment: .center) {
                        Text(viewModel.topic)
                            .font(.body)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Attendees \(viewModel.attendeeCount)")
                                .font(.caption)
                                .tint(Color(asset: Asset.Logo.Muted.green))
                            Text(
                                viewModel.createdDate,
                                format: Date.FormatStyle(
                                    date: .abbreviated,
                                    time: .omitted
                                )
                            )
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
                Image(systemName: viewModel.isChecked ? "info.circle.fill" : "circle")
                    .foregroundStyle(
                        viewModel.isChecked
                            ? Color(asset: Asset.Logo.Prominent.blue)
                            : Color(asset: Asset.Logo.Muted.blue)
                    )
            }
            .contentShape(Rectangle())
        }
    }

}

extension MainScreen.ConversationList.Row {

    struct ViewModel: Equatable, Identifiable {
        let id: Conversation.ID
        let title: String
        let topic: String
        let attendeeCount: Int
        let createdDate: Date
        let isChecked: Bool
    }

}
