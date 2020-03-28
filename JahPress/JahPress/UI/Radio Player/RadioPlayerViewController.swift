//
//  RadioPlayerViewController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftEventBus

class RadioPlayerViewController: UIViewController, AppDependencyInjectable {
    var dependencies: AppDependencies!

    var currentStation: Station?
    var radioPlayer: RadioPlayer!
    var currentErrorAlert: UIAlertController?

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stationLabel: UILabel!
    @IBOutlet weak var songFloatingLabel: FloatingLabel!
    @IBOutlet weak var coverImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        radioPlayer = RadioPlayer(logger: dependencies.globalLogger)
        radioPlayer.delegate = self

        self.coverImageView.image = UIImage(named: "placeholder")

        self.stationLabel.text = "select a radio station to listen to"
        self.stationLabel.textColor = .white
        self.songFloatingLabel.text = ""

        SwiftEventBus.onMainThread(self, name: EventIdentifiers.StationSelected) { result in

            guard let tuneIn = result?.userInfo?["tunein"] as? TuneIn, let base = tuneIn.baseM3u, let station = result?.userInfo?["station"] as? Station, let staionId = station.id else {
                return
            }

            let playListURL = URL(string: "http://yp.shoutcast.com\(base)?id=\(staionId)")
            self.currentStation = station
            self.coverImageView.image = UIImage(named: "default-cover")
            if let logoURLString = station.logo, let logoURL = URL(string: logoURLString) {
                self.dependencies.shoutcastAPI.getCoverArt(withURL: logoURL).map { image in
                    self.coverImageView.image = image
                }.catch { error in
                    self.dependencies.globalLogger.warning("couldn't load cover: \(error)")
                }
            }
            self.stationLabel.text = station.name
            self.songFloatingLabel.text = "buffering..."
            self.radioPlayer.url = playListURL
            do {
                try self.radioPlayer.startPlaying()
            } catch {
                self.dependencies.globalLogger.error("\(error)")
                if self.currentErrorAlert == nil {
                    self.currentErrorAlert = ErrorReporter().reportError(error: error, okHandler: { [weak self] _ in
                        guard self != nil else { return }
                        self!.currentErrorAlert = nil
                    })
                }
            }

            guard BuildConfiguration.environemt == .prod,
                let stationName = station.name,
                let stationId = station.id else { return }

//            AppsFlyerTracker.shared().trackEvent(AFEventContent, withValues: [
//                AFEventParamContentType: "Playing Stream",
//                AFEventParamDescription: stationName,
//                AFEventParamContentId: stationId])
        }

        SwiftEventBus.onMainThread(self, name: EventIdentifiers.MusicMuteOn, handler: { _ in
            self.radioPlayer.isMuted = true
        })

        SwiftEventBus.onMainThread(self, name: EventIdentifiers.MusicMuteOff, handler: { _ in
            self.radioPlayer.isMuted = false
        })

        SwiftEventBus.onMainThread(self, name: EventIdentifiers.MusicVolumeChanged, handler: { result in
            guard let volume = result?.userInfo?["volume"] as? Float else { return }
            self.radioPlayer.volume = volume
        })
    }

    deinit {
        SwiftEventBus.unregister(self)
    }

    @IBAction func playButton(_ sender: Any) {
        radioPlayer.pausePlaying()
    }

    func showErrorMessage() {
        self.stationLabel.text = "Failed to start stream :("
        self.songFloatingLabel.text =
        """
        Unfortunately the radio stream couldn't be startet.
        There are many possible reasons. If your internet connection is ok,
        the station could be currently unreachable or is not available any more.
        """
    }
}

extension RadioPlayerViewController: RadioPlayerDelegate {

    func radioPlayer(player: RadioPlayer, didUpdateState state: RadioPlayerState) {

        print("RadioPlayerState: \(state)")

        switch state {
        case .unknown: print("unkown player state...")
        case .preparing:
            playButton.isEnabled = false
            songFloatingLabel.text = "buffering..."
            playButton.stopFlashing()
        case .playing:
            playButton.isEnabled = true
            playButton.setImage(UIImage(named: "baseline_pause_black_48pt"), for: .normal)
            playButton.startFlashing(withInterval: 1)
        case .paused:
            playButton.isEnabled = true
            playButton.setImage(UIImage(named: "baseline_play_arrow_black_48pt"), for: .normal)
            playButton.stopFlashing()
        case .stopped:
            playButton.isEnabled = false
            playButton.stopFlashing()
        case .failed:
            showErrorMessage()
            playButton.isEnabled = false
            playButton.stopFlashing()
        }
    }

    func radioPlayer(player: RadioPlayer, didReceiveMetaData metaData: RadioPlayerMetaData) {

        switch (metaData.artist, metaData.song) {
        case (let artist, let song) where artist != nil && artist != "" && song != nil && song != "":
            songFloatingLabel.text = "\(artist!) - \(song!)"
        case (let artist, nil) where artist != nil && artist != "":
            songFloatingLabel.text = "\(artist!)"
        case (nil, let song) where song != nil && song != "":
            songFloatingLabel.text = "\(song!)"
        default:
            if let title = metaData.streamTitle, title.count > 0, !title.contains("Use HTTP to feed") {
                songFloatingLabel.text = title
            } else {
                songFloatingLabel.text = "no song info available"
            }
        }
    }

    func radioPlayer(player: RadioPlayer, encounteredError error: Error) {

        showErrorMessage()

//        if self.currentErrorAlert == nil {
//            self.currentErrorAlert = ErrorReporter().reportError(error: error, okHandler: { [weak self] _ in
//                guard self != nil else { return }
//                self!.currentErrorAlert = nil
//            })
//        }
    }
}
