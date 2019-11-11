//
//  JahAudioPlayer.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 07.01.18.
//  Copyright © 2018 Benjamin Ludwig. All rights reserved.
//

import UIKit
import AVFoundation

protocol JahAudioPlayerDelegate: class {
    func jahAudioPlayerDidFinishPlaying(player: JahAudioPlayer)
}

class JahAudioPlayer {

    weak var delegate: JahAudioPlayerDelegate?
    private var player: AVPlayer

    var volume: Float {
        get { return player.volume }
        set { player.volume = newValue }
    }

    var isMuted: Bool {
        get { return player.isMuted }
        set { player.isMuted = newValue }
    }

    private var notifications: [NSObjectProtocol] = []

    init(url: URL) {
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: AVAsset(url: url)))

        let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { _ in
            self.delegate?.jahAudioPlayerDidFinishPlaying(player: self)
        }
        notifications.append(observer)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func play() {
        self.player.play()
    }

    func stop() {
        self.player.pause()
    }
}
