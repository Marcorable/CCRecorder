//
//  NoteSetView.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/06/23.
//

import Domain

import SwiftUI

struct NoteSetView: View {
	
    // MARK: - Dependency
	@EnvironmentObject private var viewMaker: ScreenMaker
	
    let usecase: NoteUsecase
    
    // MARK: - View Render
    @State var list: [NoteEntity] = []
    
    var content: some View {
        VStack {
            List {
                ForEach(list, id: \.id) { note in
                    NoteSetRow(item: note)
                        .onTapGesture {
                            selectedRowItem = note
                            isPresentedNoteDetail.toggle()
                        }
                }
                .onDelete(perform: removeRows)
            }
            .listStyle(.plain)
        }
        .onReceive(usecase.noteSubject) { notes in
            self.list = notes
        }
    }
	
    // MARK: - View Action
	@State private var isPresentedNoteDetail: Bool = false
	@State private var selectedRowItem: NoteEntity?
	
	var body: some View {
		content
            .sheet(item: $selectedRowItem) { item in
                HalfSheet(isFlexible: item.category == .sentence) {
                    viewMaker.makeView(.noteDetail(item))
                }
            }
	}
	
}

extension NoteSetView {
    
    func removeRows(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            usecase.delete(item: list[offset]) { error in
                guard error == nil else {
                    print("\(error!)")
                    return
                }
            }
        }
    }
    
}

//#if DEBUG // MARK: - Preview
//struct NoteSetView_Previews: PreviewProvider {
//	
//	static var container: PresentationDIContainer { .preview }
//	
//	static var previews: some View {
//		container.NoteSetView()
//			.environmentObject(container)
//			.preferredColorScheme(.light)
//		container.NoteSetView()
//			.environmentObject(container)
//			.preferredColorScheme(.dark)
//	}
//
//}
//#endif
