//
//  StationList.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation

typealias DataDictionary = [String: Any]

struct StationList: Decodable {

    var lastUpdateDate: Date?

    var tuneIn: TuneIn?
    var stations: [Station]

    mutating func cleanup() {
        let allowedGenres = ["dancehall", "reggae", "ragga", "roots", "ska", "rocksteady"]
        self.stations = self.stations.filter({ station -> Bool in
            return (station.genres.filter { allowedGenres.contains($0) }.count > 0)
        })
    }
}

// val shoutCastGenreList = listOf("dancehall", "reggae", "ragga", "roots", "ska", "Rocksteady")

struct TuneIn: Decodable {
    var base: String?
    var baseM3u: String?
    var baseXspf: String?
}

struct Station: Decodable {

    var isFavorite: Bool {
        get {
            guard let id = id else { return false }
            return JahUserDefaults.contains(favoriteWith: id)
        }
        set {
            guard let id = id else { return }
            if newValue == false {
                JahUserDefaults.remove(favoriteWith: id)
            } else {
                JahUserDefaults.add(favoriteWith: id)
            }
        }
    }

    //swiftlint:disable identifier_name
    var name: String?
    var genre: String?
    var genre2: String?
    var genre3: String?
    var genre4: String?
    var genre5: String?
    var logo: String?
    var mt: String?
    var id: String?
    var br: String?
    var lc: String?
    //swiftlint:enable identifier_name

    var genres: [String] {
        return displayGenres.map { $0.lowercased() }
    }

    var displayGenres: [String] {
        return [genre, genre2, genre3, genre4, genre5].compactMap { $0 }
    }

    var listenerCount: Int {
        if let lc = lc {
            return (lc as NSString).integerValue
        }
        return 0
    }
}
