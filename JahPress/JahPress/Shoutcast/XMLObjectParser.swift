//
//  XMLObjectParser.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation
import PromiseKit

enum XMLObjectParserError: Error {
    case xmlParserError(cause: Error)
}

typealias ElementHandler = (_ elementName: String, _ attributes: [String: String], _ resultDictionary: DataDictionary) -> DataDictionary

class XMLObjectParser: NSObject {

    public var elementHandler: ElementHandler?

    private let xmlParser: XMLParser
    private var pendingParsingPromise: (promise: Promise<DataDictionary>, resolver: Resolver<DataDictionary>)?
    private var dictionaryResult: DataDictionary!

    init(xmlData: Data) {
        xmlParser = XMLParser(data: xmlData)
        super.init()
        xmlParser.delegate = self
    }

    func parseObject() -> Promise<DataDictionary> {

        guard pendingParsingPromise?.promise.isPending != true else {
            return pendingParsingPromise!.promise
        }

        let pendingPromise = Promise<DataDictionary>.pending()
        pendingParsingPromise = pendingPromise
        dictionaryResult = DataDictionary()
        xmlParser.parse()

        return pendingPromise.promise
    }
}

extension XMLObjectParser: XMLParserDelegate {

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {

        dictionaryResult = elementHandler?(elementName, attributeDict, dictionaryResult)
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        pendingParsingPromise?.resolver.fulfill(dictionaryResult)
        pendingParsingPromise = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        pendingParsingPromise?.resolver.reject(XMLObjectParserError.xmlParserError(cause: parseError))
        pendingParsingPromise = nil
    }
}
