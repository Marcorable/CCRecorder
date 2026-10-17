//
//  +setupAppConfiguration().swift
//  CCRecorderApp
//
//  Created by 김용우 on 6/2/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Foundation

extension LaunchScreenView {
    
    func setupAppConfiguration() {
        guard let filePath = Bundle.main.path(forResource: "URLs", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath) else {
            fatalError("URLs.plist 불러오기 실패")
        }
        self.mainURL = plist.object(forKey: "Main").flatMap({ $0 as? String }).flatMap({ URL(string: $0) })!
        self.cafeURL = plist.object(forKey: "Cafe").flatMap({ $0 as? String }).flatMap({ URL(string: $0) })!
        self.eLearningURL = plist.object(forKey: "eLearning").flatMap({ $0 as? String }).flatMap({ URL(string: $0) })!
        self.tasteURL = plist.object(forKey: "TastePage").flatMap({ $0 as? String }).flatMap({ mainURL.appendingPathComponent($0) })
        self.testURL = plist.object(forKey: "TestPage").flatMap({ $0 as? String }).flatMap({ mainURL.appendingPathComponent($0) })
        self.receptionTel = plist.object(forKey: "ReceptionPhoneNumber").flatMap({ $0 as? String }).flatMap({ URL(string: $0) })!
    }
    
}
