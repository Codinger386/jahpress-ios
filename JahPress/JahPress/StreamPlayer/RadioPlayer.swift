//
//  RadioPlayer.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 29.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftEventBus
import FreeStreamer
import MediaPlayer

struct RadioPlayerMetaData {
    var artist: String?
    var song: String?
    var streamTitle: String?
    var coverURL: String?
}

enum RadioPlayerState {
    case unknown
    case preparing
    case playing
    case paused
    case stopped
    case failed
}

enum RadioPlayerError: UserReadableError {

    case noStreamURLAvailable
    case couldntCreateAudioController
    case networkError
    case streamError

    var displayTitle: String {
        switch self {
        case .networkError: return "Network Error"
        default: return "Stream Error"
        }
    }

    var displayMessage: String {
        switch self {
        case .noStreamURLAvailable:  return "No stream URLs available"
        case .couldntCreateAudioController: return "AudioController couldn't be created"
        case .networkError: return "Please check your internet connection."
        case .streamError: return "There was an error with radio stream. Please try again later or try another station."
        }
    }
}

protocol RadioPlayerDelegate: class {
    func radioPlayer(player: RadioPlayer, didUpdateState state: RadioPlayerState)
    func radioPlayer(player: RadioPlayer, didReceiveMetaData metaData: RadioPlayerMetaData)
    func radioPlayer(player: RadioPlayer, encounteredError error: Error)
}

class RadioPlayer: NSObject {

    weak var delegate: RadioPlayerDelegate?
    var state: RadioPlayerState = .unknown {
        didSet {
            if state != oldValue {
                delegate?.radioPlayer(player: self, didUpdateState: state)
            }
        }
    }

    let logger: Logger?

    var url: URL?

    var volume: Float = 1.0 {
        didSet { audioController?.volume = volume }
    }

    var isMuted: Bool = false {
        didSet {
            if isMuted {
                audioController?.volume = 0
            } else {
                audioController?.volume = volume
            }
        }
    }

    lazy var streamConfiguration: FSStreamConfiguration = {
        var config = FSStreamConfiguration()
        config.automaticAudioSessionHandlingEnabled = false
        return config
    }()

    var audioController: FSAudioController?

    init(logger: Logger) {
        self.logger = logger
    }

    func startPlaying() throws {

        guard let url = url else { throw RadioPlayerError.noStreamURLAvailable }
        guard let audioController = FSAudioController(url: url) else { throw RadioPlayerError.couldntCreateAudioController }

        audioController.configuration = streamConfiguration
        audioController.delegate = self

        audioController.onStateChange = onStateChange
        audioController.onMetaDataAvailable = onMetaDataAvailable
        audioController.onFailure = onError

        audioController.play()

        self.audioController = audioController
    }

    func pausePlaying() {
        guard let controller = self.audioController else {
            logger?.error("no controller available")
            return
        }
        controller.pause()
    }

    func stopPlaying() {
        guard let controller = self.audioController else {
            logger?.error("no controller available")
            return
        }

        controller.stop()
    }

    func onStateChange(state: FSAudioStreamState) {
        logger?.info("state: \(state)")
        switch state {
        case .fsAudioStreamRetrievingURL: self.state = .preparing
        case .fsAudioStreamBuffering: self.state = .preparing
        case .fsAudioStreamPlaying: self.state = .playing
        case .fsAudioStreamPaused: self.state = .paused
        case .fsAudioStreamStopped: self.state = .stopped
        case .fsAudioStreamRetryingStarted: self.state = .preparing
        case .fsAudioStreamRetryingSucceeded: self.state = .preparing
        case .fsAudioStreamRetryingFailed: self.state = .failed
        case .fsAudioStreamFailed: self.state = .failed
        case .fsAudioStreamSeeking: print("ignoring state fsAudioStreamSeeking")
        case .fsAudioStreamPlaybackCompleted: print("ignoring state fsAudioStreamPlaybackCompleted")
        case .fsAudioStreamUnknownState: self.state = .unknown
        case .fsAudioStreamEndOfFile: print("ignoring state fsAudioStreamEndOfFile")
        }
    }

    func onMetaDataAvailable(meta: [AnyHashable: Any]?) {
        //logger?.info("meta: \(meta ?? [:])")

        self.delegate?.radioPlayer(player: self, didReceiveMetaData: RadioPlayerMetaData(
            artist: meta?[MPMediaItemPropertyArtist] as? String,
            song: meta?[MPMediaItemPropertyTitle] as? String,
            streamTitle: meta?["StreamTitle"] as? String,
            coverURL: meta?["CoverArt"] as? String)
        )
    }

    func onError(error: FSAudioStreamError, errorDescription: String?) {
        logger?.error("error: \(error)")

        switch error {
        case .fsAudioStreamErrorNetwork: delegate?.radioPlayer(player: self, encounteredError: RadioPlayerError.networkError)
        case .fsAudioStreamErrorNone: print("no error, hun?!?")
        case .fsAudioStreamErrorOpen,
             .fsAudioStreamErrorStreamBouncing,
             .fsAudioStreamErrorStreamParse,
             .fsAudioStreamErrorTerminated,
             .fsAudioStreamErrorUnsupportedFormat:
            delegate?.radioPlayer(player: self, encounteredError: RadioPlayerError.streamError)
        }
    }
}

extension RadioPlayer: FSAudioControllerDelegate {

    func audioController(_ audioController: FSAudioController!, preloadStartedFor stream: FSAudioStream!) {

    }

    func audioController(_ audioController: FSAudioController!, allowPreloadingFor stream: FSAudioStream!) -> Bool {
        return true
    }
}
