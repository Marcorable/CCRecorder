//
//  NoteSetRow.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/08.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Domain

import SwiftUI

struct NoteSetRow: View {
	
    let item: NoteEntity
	
	var body: some View {
		HStack {
            Image(systemName: categoryImageName)
                .foregroundColor(.logoLightRed)
                .frame(width: 36, alignment: .center)
            if item.isDone {
                VStack(alignment: .leading) {
                    Text(item.original)
                    Text(item.translation)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.logoLightBlue)
            } else {
                VStack {
                    Text(noteContentLabel)
                }
                Spacer()
                Image(systemName: noteContentImageName)
                    .foregroundColor(.logoDarkBlue)
            }
		}
		.font(.body)
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
	}
	
}

extension NoteSetRow {
	
    private var categoryImageName: String {
        item.category == .sentence ? "text.bubble.fill" : "textformat.abc"
    }
    private var noteContentLabel: String {
        item.original.isEmpty ? item.original : item.original
    }
    private var noteContentImageName: String {
        item.original.isEmpty ? "k.circle" : "e.circle"
    }
	
}

#Preview("dark) 영어") {
    NoteSetRow(
        item: .init(
            id: .init(),
            original: "Nice to meet you.",
            translation: "",
            category: .sentence,
            references: [],
            createdDate: Date()
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("light) 한글") {
    NoteSetRow(
        item: .init(
            id: .init(),
            original: "",
            translation: "한국말 문장만 있는 노트",
            category: .sentence,
            references: [],
            createdDate: Date()
        )
    )
    .preferredColorScheme(.light)
}
