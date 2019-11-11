//
//  StationsParser.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation
import PromiseKit

class StationsParser {

    class func parseStations(xmlData: Data, logger: Logger? = nil) -> Promise<StationList> {

        return Promise<StationList> { resolvers in

            let xmlObjectParser = XMLObjectParser(xmlData: xmlData)

            xmlObjectParser.elementHandler = { elementName, attributes, resultDictionary in

                var dict = resultDictionary

                if elementName == "tunein" {
                    var portedAttributes: [String: String] = [:]
                    portedAttributes["base"] = attributes["base"]
                    portedAttributes["baseM3u"] = attributes["base-m3u"]
                    portedAttributes["baseXspf"] = attributes["base-xspf"]
                    dict["tuneIn"] = portedAttributes
                }

                if elementName == "station" {
                    if dict["stations"] == nil {
                        dict["stations"] = [[String: String]]()
                    }
                    if var array = dict["stations"] as? [[String: String]] {
                        array.append(attributes)
                        dict["stations"] = array
                    }
                }

                return dict
            }

            xmlObjectParser.parseObject().map { objectDictionary in

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: objectDictionary, options: .prettyPrinted)
                    let decoder = JSONDecoder()
                    let stationList = try decoder.decode(StationList.self, from: jsonData)
                    resolvers.fulfill(stationList)

                } catch {
                    resolvers.reject(error)
                }

            }.catch { error in
                resolvers.reject(error)
            }
        }
    }
}
