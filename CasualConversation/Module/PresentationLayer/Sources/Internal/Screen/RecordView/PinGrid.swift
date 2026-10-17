//
//  PinGrid.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import SwiftUI

struct PinGrid: View {
    @Binding var pins: [TimeInterval]
    let isRecording: Bool
    let currentTime: TimeInterval
    
    var body: some View {
        ScrollView {
            Spacer()
            VStack {
                Spacer(minLength: 30)
                HStack {
                    Spacer()
                    Image(systemName: "circle.fill")
                        .foregroundColor(isRecording ? .logoLightRed : .logoDarkRed)
                        .opacity(isRecording ? Int(currentTime) % 2 == 0 ? 1.0 : 0.0 : 1.0)
                    Text(currentTime.formattedToDisplayTime)
                        .foregroundColor(isRecording ? .white : .gray)
                        .font(.largeTitle)
                    Spacer()
                }
                Spacer()
                List {
                    ForEach(pins, id: \.self) { time in
                        HStack {
                            Text("📌 \(time.formattedToDisplayTime)")
                            Spacer()
                            Button(
                                action: {
                                    guard let index = pins.firstIndex(of: time) else {
                                        return
                                    }
                                    self.pins.remove(at: index)
                                }, label: {
                                    Image(systemName: "delete.backward")
                                        .foregroundColor(.logoLightRed)
                                }
                            )
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .padding()
                .listStyle(.plain)
                .background(Color.clear)
            } // RecordInfo
            Spacer()
        }
    }
}

#Preview {
    PinGrid(
        pins: .constant([3.0, 2.1]),
        isRecording: true,
        currentTime: .init()
    )
}
