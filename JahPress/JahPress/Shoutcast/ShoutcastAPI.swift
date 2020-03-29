//
//  ShoutcastAPI.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import PromiseKit
import UIKit

enum ShoutcastAPIError: Error {
    case stationHasNoId(station: Station)
    case imageDataCouldNotBeParsed
}

class ShoutcastAPI {

    private let cacheLifeTimeInSeconds: TimeInterval = 3600 * 3
    private var imageCache: [String: UIImage] = [:]

    let dataStore: DataStore
    let networkService: NetworkService
    let logger: Logger?

    init(dataStore: DataStore, networkService: NetworkService, logger: Logger? = nil) {
        self.dataStore = dataStore
        self.networkService = networkService
        self.logger = logger
    }

    func getReggaeStations() -> Promise<StationList> {

        if let stationList: StationList = dataStore.stationList,
            let lastUpdateDate = stationList.lastUpdateDate,
            lastUpdateDate > Date().addingTimeInterval(-cacheLifeTimeInSeconds) {
            return Promise.value(stationList)
        }

        let apiKey = BuildConfiguration.shoutcastAPIKey

        return networkService.get(from: "http://api.shoutcast.com/legacy/genresearch", data: ["k": apiKey, "genre": "reggae"]).then { data -> Promise<StationList> in
            return StationsParser.parseStations(xmlData: data, logger: self.logger).then { list -> Promise<StationList> in
                var list = list
                list.lastUpdateDate = Date()
                list.cleanup()
                self.dataStore.stationList = list
                return Promise.value(list)
            }
        }
    }

    func getCoverArt(withURL url: URL) -> Promise<UIImage> {
        if let image = imageCache[url.absoluteString] {
            return Promise<UIImage>.value(image)
        }
        return networkService.get(from: url.absoluteString, data: nil).then { data -> Promise<UIImage> in
            guard let image = UIImage(data: data) else { return Promise(error: ShoutcastAPIError.imageDataCouldNotBeParsed) }
            self.imageCache[url.absoluteString] = image
            return Promise<UIImage>.value(image)
        }
    }

    func getURLs(forM3UBase base: String, station: Station) -> Promise<[URL]> {
        guard station.id != nil else { return Promise(error: ShoutcastAPIError.stationHasNoId(station: station)) }

        return networkService.get(from: "http://yp.shoutcast.com\(base)", data: ["id": "\(station.id!)"]).then { data -> Promise<[URL]> in
            var urls = [URL]()
            let m3uFileString = String(data: data, encoding: String.Encoding.ascii)
            m3uFileString?.components(separatedBy: "\n").forEach { line in
                let lineString = line as NSString
                if lineString.hasPrefix("http"), let url = URL(string: lineString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                    urls.append(url)
                }
            }
            return Promise.value(urls)
        }
    }
}
