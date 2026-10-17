//
//  ConversationListView.swift
//  CasualConversation
//
//  Created by Yongwoo Marco on 2022/07/04.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Domain
import SwiftUI

struct ConversationListView: View {
	
    // MARK: - Dependency
	@EnvironmentObject private var screenMaker: ScreenMaker
    
    let usecase: ConversationUsecase
    let player: CCPlayer
    
    // MARK: - View Render
    @State private var dataSource: [ConversationEntity] = []
    
    var content: some View {
        List {
            ForEach(dataSource, id: \.id) { item in
                NavigationLink(
                    destination: screenMaker.makeView(.selection(item)),
                    label: { ConversationListRow(item: item) }
                )
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(.plain)
    }

    // MARK: - View Action
	var body: some View {
		content
            .onReceive(usecase.conversationSubejct) { dataSource in
                self.dataSource = dataSource
            }
	}

    // MARK: - Private Methods
    func onDelete(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            let item = dataSource[offset]
            player.removeRecordFile(from: item.recordFilePath) { error in
                if let error = error {
                    print(error)
                }
            }
            // FIXME: id 또는 index로 삭제하도록 수정 필요
            usecase.delete(item) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
}

#if DEBUG
//#Preview {
//    ConversationListView(
//        usecase: FakeConversationUsecase(),
//        player: FakeCCPlayer()
//    )
//    .preferredColorScheme(.light)
//}
//
//#Preview {
//    ConversationListView(
//        usecase: FakeConversationUsecase(),
//        player: FakeCCPlayer()
//    )
//    .preferredColorScheme(.dark)
//}
#endif
