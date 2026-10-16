//
//  RecordControlBoard.swift
//  Presentation
//
//  Created by 김용우 on 6/19/24.
//  Copyright © 2024 pseapplications. All rights reserved.
//

import Domain

import SwiftUI

struct RecordControlBoard: View {
    let audioService: CCRecorder
    @Binding var isPresentedConfirmStop: Bool
    @Binding var pins: [TimeInterval]
    let currentTime: TimeInterval
    let isRecording: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            Button(
                action: { isPresentedConfirmStop.toggle() },
                label: {
                    Spacer()
                    ZStack {
                        Image(systemName: "stop.fill")
                            .foregroundColor(currentTime > 0 ? .logoLightBlue : .logoDarkBlue)
                            .font(.system(size: 34))
                            .shadow(color: .logoDarkBlue, radius: 1, x: 2, y: 2)
                    }
                    Spacer()
                }
            ) // StopButton
            .disabled(currentTime <= 0)
            
            Spacer()
            Button(
                action: {
                    if isRecording {
                        audioService.pause()
                    } else {
                        audioService.start()
                    }
                }, label: {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 2)
                            .frame(width: 66, height: 66, alignment: .center)
                            .foregroundColor(.white)
                        if isRecording {
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.logoDarkRed)
                                    .font(.system(size: 58))
                                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                                Image(systemName: "pause.fill")
                                    .foregroundColor(.logoLightRed)
                                    .font(.system(size: 34))
                                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                            }
                        } else {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.logoLightRed)
                                .font(.system(size: 58))
                                .shadow(color: .logoDarkBlue, radius: 1, x: 1, y: 1)
                        }
                    }
                }
            ) // RecordButton
            Spacer()
            Button(
                action: {
                    guard currentTime > 0,
                          pins.filter(
                            { Int($0) % 60 == Int(currentTime) % 60 }
                          ).count == 0
                    else {
                        return
                    }
                    self.pins.append(currentTime)
                }, label: {
                    Spacer()
                    ZStack {
                        Image(systemName: "pin")
                            .foregroundColor(isRecording ? .logoLightBlue : .logoDarkBlue)
                            .font(.system(size: 26))
                            .shadow(color: .logoDarkBlue, radius: 1, x: 2, y: 2)
                    }
                    Spacer()
                }
            ) // PinButton
            .disabled(!isRecording)
        }
    }
}

#if DEBUG
#Preview("라이트 모드") {
    RecordControlBoard(
        audioService: FakeCCRecorder(),
        isPresentedConfirmStop: .constant(false), 
        pins: .constant([3.0]),
        currentTime: .zero,
        isRecording: false
    )
    .preferredColorScheme(.light)
}
#Preview("다크 모드") {
    RecordControlBoard(
        audioService: FakeCCRecorder(),
        isPresentedConfirmStop: .constant(false),
        pins: .constant([3.0]),
        currentTime: .zero,
        isRecording: false
    )
    .preferredColorScheme(.dark)
}
#endif
