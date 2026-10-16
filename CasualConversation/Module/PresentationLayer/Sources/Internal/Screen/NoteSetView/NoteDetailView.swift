//
//  NoteDetail.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/08.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Domain

import SwiftUI
import Combine

// TODO: UI 구성 디벨롭 필요
struct NoteDetailView: View {
	
    // MARK: - Dependency
	@Environment(\.presentationMode) private var presentationMode
    
    let item: NoteEntity
    let usecase: NoteUsecase
    
    init(
        item: NoteEntity,
        usecase: NoteUsecase
    ) {
        self.item = item
        self.usecase = usecase
        
        self._original = State(initialValue: item.original)
        self._translation = State(initialValue: item.translation)
    }

    // MARK: - View Render
    var isVocabulary: Bool { item.category == .vocabulary }
    
    var content: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if isVocabulary {
                    VStack(alignment: .leading) {
                        Spacer()
                        InputTextField(
                            title: "단어 Original",
                            iconName: "e.circle.fill",
                            text: $original
                        )
                        InputTextField(
                            title: "번역 Translation",
                            iconName: "k.circle.fill",
                            text: $translation
                        )
                        Spacer()
                    }
                } else {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "e.circle.fill")
                                .foregroundColor(.logoLightBlue)
                            Text("문장 Original")
                        }
                        TextEditor(text: $original)
                            .onChange(of: original) { value in
                                isEdited = true
                            }
                            .background(
                                Color.ccBgColor
                                    .cornerRadius(15)
                            )
                        HStack {
                            Image(systemName: "k.circle.fill")
                                .foregroundColor(.logoLightBlue)
                            Text("번역 Translation")
                        }
                        TextEditor(text: $translation)
                            .onChange(of: translation) { value in
                                isEdited = true
                            }
                            .background(
                                Color.ccBgColor
                                    .cornerRadius(15)
                            )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .toolbar(
                NoteDetailViewToolBar(
                    isEdited: isEdited,
                    title: self.isVocabulary ? "Vocabulary" : "Sentense",
                    imageSystemName: self.isVocabulary ? "textformat.abc" : "text.bubble.fill",
                    saveAction: {
                        updateChanges()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            )
        }
    }
    	
    // MARK: - View Action
    @State var isEdited: Bool = false
    @State var original: String
    @State var translation: String
    
	var body: some View {
        content
            .onChange(of: original) { newValue in
                if !isEdited, self.original != newValue {
                    isEdited = true
                }
            }
            .onChange(of: translation) { newValue in
                if !isEdited, self.translation != newValue {
                    isEdited = true
                }
            }
	}
    
    func updateChanges() {
        let newItem: NoteEntity = .init(
            id: item.id,
            original: original.trimmingCharacters(in: [" "]),
            translation: translation.trimmingCharacters(in: [" "]),
            category: item.category,
            references: item.references,
            createdDate: item.createdDate
        )
        usecase.edit(newItem) { error in
            guard error == nil else {
                print("error \(error!)")
                return
            }
        }
    }
    
}

fileprivate struct InputTextField: View {
    @State var title: String
    @State var iconName: String
    @State var text: Binding<String>
    
    var body: some View {
        Group {
            Text(title)
                .font(.headline)
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.logoLightBlue)
                TextField(title,
                          text: text,
                          prompt: Text(title.components(separatedBy: " ")[0]))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
}
