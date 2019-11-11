//
//  Dictionary+KeypathExtension.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//
//  Adopted from https://oleb.net/blog/2017/01/dictionary-key-paths/

struct DictionaryKeyPath {
    var segments: [String]

    var isEmpty: Bool { return segments.isEmpty }
    var path: String {
        return segments.joined(separator: ".")
    }

    func headAndTail() -> (head: String, tail: DictionaryKeyPath) {
        var tail = segments
        let head = tail.removeFirst()
        return (head, DictionaryKeyPath(segments: tail))
    }
}

extension DictionaryKeyPath {
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
}

extension DictionaryKeyPath: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Dictionary where Key == String, Value == Any {
    subscript(keyPath keyPath: DictionaryKeyPath) -> Any? {
        get {
            guard keyPath.headAndTail().head != "" else { return self }
            switch keyPath.headAndTail() {
            case let (head, remainingKeyPath) where remainingKeyPath.isEmpty:
                return self[head]
            case let (head, remainingKeyPath):
                switch self[head] {
                case let nestedDict as [Key: Any]:
                    return nestedDict[keyPath: remainingKeyPath]
                default:
                    return nil
                }
            }
        }

        set {
            switch keyPath.headAndTail() {
            case let (head, remainingKeyPath) where remainingKeyPath.isEmpty:
                self[head] = newValue
            case let (head, remainingKeyPath):
                let value = self[head]
                switch value {
                case var nestedDict as [Key: Any]:
                    nestedDict[keyPath: remainingKeyPath] = newValue
                    self[head] = nestedDict
                default:
                    return
                }
            }
        }
    }
}
