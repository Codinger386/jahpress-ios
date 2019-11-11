//
//  EffectView.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 28.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import QuartzCore
import UIKit
import SwiftEventBus

class EffectView: UIView {

    static var soundTracked: Bool = false

    static var volume: Float = 1 {
        didSet {
            SwiftEventBus.post(EventIdentifiers.EffectVolumeChanged, userInfo: ["volume": volume])
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var gradient: UIImageView!

    var effect: Effect!
    var logger: Logger?

    var jahAudioPlayer: JahAudioPlayer? {
        didSet {
            if jahAudioPlayer == nil {
                SwiftEventBus.unregister(self)
            } else {
                SwiftEventBus.onMainThread(self, name: EventIdentifiers.EffectVolumeChanged) { result in
                    guard let volume: Float = result?.userInfo?["volume"] as? Float else { return }
                    self.jahAudioPlayer?.volume = volume
                }

                SwiftEventBus.onMainThread(self, name: EventIdentifiers.EffectMuteOn, handler: { _ in
                    self.jahAudioPlayer?.isMuted = true
                })

                SwiftEventBus.onMainThread(self, name: EventIdentifiers.EffectMuteOff, handler: { _ in
                    self.jahAudioPlayer?.isMuted = false
                })
            }
        }
    }

    init(frame: CGRect, effect: Effect) {
        self.effect = effect
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    func setupUI() {
        //self.cornerRadius = 5
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 1
    }

    @IBAction func effectButton(_ sender: Any) {
        if BuildConfiguration.environemt == .prod && !EffectView.soundTracked {
//            AppsFlyerTracker.shared().trackEvent(AFEventContent, withValues: [
//                AFEventParamContentType: "Using Sound Effects"])
            EffectView.soundTracked = true
        }
        playEffect()
    }

    func playEffect() {

        if jahAudioPlayer != nil {
            jahAudioPlayer?.isMuted = true
            jahAudioPlayer?.stop()
            jahAudioPlayer = nil
        }

        let effectFileURL = URL(fileURLWithPath: effect.file)
        self.jahAudioPlayer = JahAudioPlayer(url: effectFileURL)
        self.jahAudioPlayer?.volume = EffectView.volume
        self.jahAudioPlayer?.delegate = self
        self.jahAudioPlayer?.play()
        startAnimation()
    }

    private func startAnimation() {
        layer.removeAllAnimations()
        let flashing = CABasicAnimation(keyPath: "opacity")
        flashing.fromValue = 0.5
        flashing.toValue = 0.1
        flashing.duration = 0.4
        flashing.autoreverses = true
        flashing.isRemovedOnCompletion = false
        flashing.repeatCount = .infinity
        gradient.layer.add(flashing, forKey: "flashing")
    }

    private func stopAnimation() {
        gradient.layer.removeAllAnimations()
    }
}

extension EffectView: JahAudioPlayerDelegate {

    func jahAudioPlayerDidFinishPlaying(player: JahAudioPlayer) {
        self.jahAudioPlayer = nil
        stopAnimation()
    }
}
