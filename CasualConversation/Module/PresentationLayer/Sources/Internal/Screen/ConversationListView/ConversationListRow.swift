//
//  ConversationListRow.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/08/08.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Domain
import SwiftUI

struct ConversationListRow: View {
    let item: ConversationEntity
		
	var body: some View {
		HStack {
            Image(systemName: "recordingtape")
                .foregroundColor(.logoLightRed)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(alignment: .center) {
                    Text(topic)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(members)
                            .font(.caption)
                            .foregroundColor(.logoDarkGreen)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(recordedDate)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
			Spacer()
            Image(systemName: checkerImageName)
                .foregroundColor(foregroundColor)
		}
	}
    
}

extension ConversationListRow {
    
    var title: String { item.title ?? "" }
    var topic: String { item.topic ?? "" }
    var members: String { item.members.joined(separator: ", ") }
    var recordedDate: String { item.recordedDate.formattedString }
    var isChecked: Bool { !title.isEmpty && !topic.isEmpty && members.isEmpty }
    var checkerImageName: String { isChecked ? "info.circle.fill" : "circle" }
    var foregroundColor: Color { isChecked ? .logoLightBlue : .logoDarkBlue }
    
}

#if DEBUG
#Preview {
    ConversationListRow(item: .preview)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
}

#Preview {
    ConversationListRow(item: .preview)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
}
#endif
