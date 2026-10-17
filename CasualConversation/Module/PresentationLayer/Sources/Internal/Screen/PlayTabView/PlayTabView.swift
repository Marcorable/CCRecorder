//
//  PlayTabView.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/10.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import SwiftUI

struct PlayTabView: View {
    
    // MARK: - Dependency
    
	@ObservedObject var viewModel: PlayTabViewModel
    
    // MARK: - View Render
    var content: some View {
        VStack(alignment: .center) {
            Slider(
                value: $viewModel.currentTime,
                in: .zero...viewModel.duration,
                onEditingChanged: { isEditing in
                    if isEditing {
                        viewModel.editingSliderPointer()
                    } else {
                        viewModel.editedSliderPointer()
                    }
                }
            )
            .padding([.leading, .trailing])
            HStack(alignment: .top) {
                Text(viewModel.currentTime.formattedToDisplayTime)
                Spacer()
                Text(viewModel.duration.formattedToDisplayTime)
            }
            .padding([.leading, .trailing])
            .foregroundColor(.gray)
            .font(.caption)
            .overlay {
                if disabledPlaying {
                    Text("녹음 파일 없음")
                        .font(.headline)
                }
            }
            HStack(alignment: .center) {
                Menu(
                    content: {
                        ForEach(Speed.allCases, id: \.self) { speed in
                            Button(action: {
                                viewModel.speed = speed
                            }, label: {
                                Text(speedDescription(of: viewModel.speed))
                                    .foregroundColor(.logoDarkBlue)
                                    .font(.caption)
                            })
                        }
                    }, label: {
                        Spacer()
                        Text(speedDescription(of: viewModel.speed))
                            .foregroundColor(.logoDarkBlue)
                            .font(.headline)
                        Spacer()
                    }
                ) // SpeedMenu
                
                Button(
                    action: {
                        viewModel.skip(.back)
                    }, label: {
                        Spacer()
                        Image(systemName: "gobackward." + viewModel.skipTime)
                            .font(.system(size: 22))
                        Spacer()
                    }
                ) // BackwardButton
                .disabled(disabledPlaying)
                .opacity(disabledPlaying ? 0.3 : 1.0)
                
                Button(
                    action: {
                        if viewModel.isPlaying {
                            viewModel.pause()
                        } else {
                            viewModel.start()
                        }
                    }, label: {
                        Spacer()
                        Image(systemName: isPlayingImageName)
                            .font(.system(size: 44))
                        Spacer()
                    }
                ) // PlayButton
                .disabled(disabledPlaying)
                
                Button(
                    action: {
                        viewModel.skip(.forward)
                    }, label: {
                        Spacer()
                        Image(systemName: "goforward." + viewModel.skipTime)
                            .font(.system(size: 22))
                        Spacer()
                    }
                ) // GowardButton
                .disabled(disabledPlaying)
                .opacity(disabledPlaying ? 0.3 : 1.0)
                
                Button(
                    action: {
                        viewModel.skip(.next)
                    }, label: {
                        Spacer()
                        Image(systemName: "forward.end.alt.fill")
                            .font(.system(size: 16))
                        Spacer()
                    }
                ) // NextPinButton
                .foregroundColor(.logoDarkBlue)
                .disabled(viewModel.pinDisabled)
                .opacity(viewModel.pinDisabled ? 0.3 : 1.0)
            }
            .foregroundColor(.logoLightBlue)
        } // PlayControl
        .background(Color.ccGroupBgColor)
    }
    
    // MARK: - View Action
    var body: some View {
		content
            .onAppear {
                viewModel.setup()
            }
            .onDisappear {
                viewModel.finish()
            }
    }
	
}

extension PlayTabView {
    
    private func speedDescription(of speed: Speed) -> String {
        let format: String
        switch speed {
        case .half, .default, .oneAndHalf, .double:
            format = "%.1fx"
        default:
            format = "%.2fx"
        }
        return .init(format: format, speed.rawValue)
    }
    
    private var disabledPlaying: Bool {
        viewModel.duration == .zero
    }
    
    private var isPlayingImageName: String {
        if disabledPlaying {
            return "speaker.slash.circle.fill"
        } else {
            return viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        }
    }
    
}

//#if DEBUG // MARK: - Preview
//struct PlayTabView_Previews: PreviewProvider {
//    
//	static var container: PresentationDIContainer { .preview }
//	
//	static var previews: some View {
//		container.PlayTabView(with: .empty)
//			.previewLayout(.sizeThatFits)
//			.preferredColorScheme(.light)
//		container.PlayTabView(with: .empty)
//			.previewLayout(.sizeThatFits)
//			.preferredColorScheme(.dark)
//    }
//	
//}
//#endif
