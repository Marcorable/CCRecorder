//
//  Member.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

struct Member: Hashable {
    let name: String
    let emoji: String
}

#if DEBUG
extension Member {
    static var previewList: [Member] {
        [
            Member(name: "테스터1", emoji: "😀"),
            Member(name: "테스터2", emoji: "😃"),
            Member(name: "테스터3", emoji: "😄")
        ]
    }
}
#endif
