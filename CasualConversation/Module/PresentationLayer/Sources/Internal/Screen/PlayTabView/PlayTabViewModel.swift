//
//  PlayTabViewModel.swift
//  Presentation
//
//  Created by Yongwoo Marco on 2022/08/10.
//  Copyright © 2022 pseapplications. All rights reserved.
//

import Common
import Domain

import SwiftUI
import Combine

final class PlayTabViewModel: ObservableObject {
	
	enum Direction {
		case forward
		case back
		case next
	}
	
	struct Dependency {
		let item: ConversationEntity
		let player: CCPlayer
	}
	private let dependency: Dependency
	
	@Published var speed: Speed = .default
	@Published var isPlaying: Bool = false
	@Published var currentTime: TimeInterval = .zero
	@Published var duration: TimeInterval = .zero
	
    var pinDisabled: Bool {
        dependency.item.pins.filter({ currentTime >= $0 }).isEmpty
    }
    private var skipSecond: Double = Preference.shared.skipTime.rawValue
	private var cancellableSet = Set<AnyCancellable>()
	
	init(dependency: Dependency) {
		self.dependency = dependency
		
		bind()
	}
	
}

extension PlayTabViewModel {
	
	var skipTime: String {
		"\(Int(skipSecond))"
	}
	
    
    private func bind() {
        dependency.player.isPlayingSubject
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellableSet)
        
        dependency.player.timeSubject
            .sink { [weak self] currentTime, duration in
                self?.currentTime = currentTime
                self?.duration = duration
            }
            .store(in: &cancellableSet)
        
        $speed
            .sink { [weak self] speed in
                self?.dependency.player.changePlayingRate(to: speed.rawValue)
            }
            .store(in: &cancellableSet)
    }
	
}

extension PlayTabViewModel {
	
	func setup() {
		let filePath = dependency.item.recordFilePath
		self.dependency.player.setup(filePath: filePath) { error in
			guard error == nil else {
				return
			}
		}
	}
	
	func start() {
		self.dependency.player.start()
	}
	
	func pause() {
		self.dependency.player.pause()
	}
	
    func skip(_ direction: Direction) {
        let timeToSeek: Double
        switch direction {
            case .forward:
                timeToSeek = currentTime + skipSecond
            case .back:
                timeToSeek = currentTime - skipSecond
            case .next:
                let leftPins = dependency.item.pins.filter({ currentTime >= $0 })
                guard let nextTimeToSeek = leftPins.first else {
                    return
                }
                timeToSeek = nextTimeToSeek
        }
        self.currentTime = timeToSeek
        self.dependency.player.seek(to: timeToSeek)
    }
    
    func editingSliderPointer() {
        self.dependency.player.stopTrackingCurrentTime()
    }
	
	func editedSliderPointer() {
		self.dependency.player.seek(to: currentTime)
	}
	
	func finish() {
		self.dependency.player.finish()
	}
	
}

