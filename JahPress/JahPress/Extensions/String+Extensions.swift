//
//  String+Extensions.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//


import Foundation

extension String {
    subscript (i: Int) -> Character? {
        guard i < self.count else {return nil}
        return self[index(startIndex, offsetBy: i)]
    }
}

extension String {
    func decodeQuery() -> [String: String] {
        guard self.count > 0 else {
            return [:]
        }
        let keyValuePairs = self.split(separator: "&")
        var dict = [String: String]()
        for kvPair in keyValuePairs {
            let keyAndValue = kvPair.split(separator: "=")
            if keyAndValue.count == 2 {
                let key = String(keyAndValue[0]).removingPercentEncoding!
                let value = String(keyAndValue[1]).removingPercentEncoding!
                dict[key] = value
            }
        }

        return dict
    }
}

extension String {
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    mutating func lowercaseFirstLetter() {
        self = self.lowercasingFirstLetter()
    }

    func uppercasingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }

    mutating func uppercaseFirstLetter() {
        self = self.uppercasingFirstLetter()
    }
}
