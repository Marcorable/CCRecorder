//
//  TeamMateInfoView.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/29.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import SwiftUI

struct TeamMateInfoView: View {
    
    private let teamMates: [TeamMate] = [
        .init(
            imageName: "profile_marco",
            name: "Marco",
            role: "Team Leader\niOS Development",
            links: [
                ("github", "https://github.com/keeplo"),
                ("blog", "https://keeplo.tistory.com"),
                ("AppStore", "https://apps.apple.com/kr/developer/id1642134370")
            ]
        ),
        .init(
            imageName: "profile_coda",
            name: "Coda",
            role: "Project Management",
            links: [
                ("github", "https://github.com/dacodaco"),
                ("blog", "https://codable.space"),
                ("AppStore", "https://apps.apple.com/kr/developer/id1604589992")
            ]
        )
    ]
    
    var body: some View {
        VStack {
            ForEach(teamMates, id: \.imageName) { teamMate in
                MemberInfo(teamMate: teamMate)
            }
            Spacer()
		}
		.navigationTitle("Team Marcoda")
    }
}

fileprivate struct TeamMate {
    let imageName: String
    let name: String
    let role: String
    let links: [(title: String, url: String)]
}

fileprivate struct MemberInfo: View {
    let teamMate: TeamMate
    
    var body: some View {
		GroupBox {
			HStack {
				Image(teamMate.imageName, bundle: .module)
					.resizable()
					.frame(width: 100, height: 100)
					.mask(Circle())
					.padding()
				VStack(alignment: .leading) {
					Text(teamMate.name)
						.font(.headline)
					Text(teamMate.role)
						.font(.subheadline)
					HStack {
						ForEach(teamMate.links, id: \.0) { link in
							Link(link.title, destination: .init(string: link.url)!)
								.font(.caption)
						}
					}
				}
				Spacer()
			}
		} // MemberInfo
		.padding([.leading, .trailing])
	}
	
}

#Preview("라이트 모드") {
    TeamMateInfoView()
        .preferredColorScheme(.light)
}
#Preview("다크 모드") {
    TeamMateInfoView()
        .preferredColorScheme(.dark)
}
