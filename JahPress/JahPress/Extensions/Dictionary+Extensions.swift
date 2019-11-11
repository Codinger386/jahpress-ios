//
//  Dictionary+Extensions.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation

extension Dictionary where Value: Any {
    func isEqual(to otherDict: [Key: Any]) -> Bool {
        guard self.count == otherDict.count else { return false }
        for (k1, v1) in self {
            guard let v2 = otherDict[k1] else { return false }
            switch (v1, v2) {
            case (let v1 as Double, let v2 as Double) : if !(v1.isEqual(to: v2)) { return false }
            case (let v1 as Float, let v2 as Float) : if !(v1.isEqual(to: v2)) { return false }
            case (let v1 as Int, let v2 as Int) : if !(v1==v2) { return false }
            case (let v1 as String, let v2 as String): if !(v1==v2) { return false }
            case (let v1 as Bool, let v2 as Bool): if !(v1==v2) { return false }
            case (let v1 as [String: Any], let v2 as [String: Any]): if !(v1.isEqual(to: v2)) { return false }
            default: return false
            }
        }
        return true
    }

    mutating func merge(with dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }

    func merged(with dictionary: Dictionary) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}
