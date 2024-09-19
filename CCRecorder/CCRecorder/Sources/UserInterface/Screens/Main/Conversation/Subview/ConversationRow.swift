//
//  ConversationRow.swift
//  CCRecorder
//
//  Created by 김용우 on 9/9/24.
//

import SwiftUI

struct ConversationListRow: View {
    @Environment(\.colorScheme) var colorScheme
    
    let conversation: Conversation
        
    var body: some View {
        HStack {
            Image(systemName: "recordingtape")
                .foregroundStyle(Color.Light.logoRed)
            VStack(alignment: .leading) {
                Text(conversation.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(alignment: .center) {
                    Text(conversation.topic)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Attendees \(conversation.parties.count)")
                            .font(.caption)
                            .tint(.Dark.logoGreen)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(conversation.createdDate.rowDescription)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Image(systemName: checkerImageName)
                .foregroundStyle(checkImageColor)
        }
        .contentShape(Rectangle())
    }
    
    private var isChecked: Bool { !conversation.title.isEmpty && !conversation.topic.isEmpty && !conversation.parties.isEmpty }
    private var checkerImageName: String { isChecked ? "info.circle.fill" : "circle" }
    private var checkImageColor: Color { isChecked ? .Light.logoBlue : .Dark.logoBlue }
    
}
