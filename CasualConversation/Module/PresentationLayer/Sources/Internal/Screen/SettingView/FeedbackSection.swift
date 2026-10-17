//
//  FeedbackSection.swift
//  Presentation
//
//  Created by 김용우 on 6/20/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI
import StoreKit
import MessageUI

struct FeedbackSection: View {
    @State var isShowingActivityView: Bool = false
    @State private var isShowingMailView: Bool = false
    @State var mailSendedResult: Result<MFMailComposeResult,Error>? {
        // TODO: Mail 완료 후 처리 필요
        willSet {
            guard let result = newValue else {
                return
            }
            switch result {
            case .success(let mailComposeResult):
                print("\(mailComposeResult)")
            case .failure(let _):
                print("error CCError.log.append(.catchError(error))")
            }
        }
    }
    
    var body: some View {
        content
            .sheet(isPresented: $isShowingMailView) {
                MailView(
                    isShowing: $isShowingMailView,
                    result: $mailSendedResult
                )
            }
            .background {
                ActivityView(isPresented: $isShowingActivityView)
            }
    }
    
    var content: some View {
        Section(
            content: {
                Link(
                    destination: .init(
                        string: "https://www.instagram.com/casualconversation_ccrecorder/")!,
                    label: {
                        Label("인스타그램 소통하기", systemImage: "hand.thumbsup")
                    }
                )
                Button(
                    action: { isShowingMailView.toggle() },
                    label: { Label("문의하기", systemImage: "envelope.open") }
                )
                Button(
                    action: {
                        guard let currentScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                            print("error UNABLE TO GET CURRENT SCENE")
                              return
                        }
                        SKStoreReviewController.requestReview(in: currentScene)
                    }, label: {
                        Label("별점주기", systemImage: "star.leadinghalf.filled")
                    }
                )
                Button(
                    action: {
                        self.isShowingActivityView.toggle()
                    }, label: {
                        Label("공유하기", systemImage: "square.and.arrow.up")
                    }
                )
            }, header: {
                Text("소통")
            }
        ) // FeedbackSection
        .tint(.primary)
    }
}

#Preview {
    FeedbackSection()
}
