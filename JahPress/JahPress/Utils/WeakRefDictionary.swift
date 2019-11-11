//
//  WeakRefDictionary.swift
//  RedOne
//
//  Created by Benjamin Ludwig on 25.01.18.
//  Copyright © 2018 Coca-Cola European Partners. All rights reserved.
//

struct WeakRefDictionary<Key, Value> where Key: Hashable, Value: AnyObject {

    typealias DictionaryType = [Key: Value]

    private var _elements: [Key: WeakRef<Value>] = [:]

    private var internalDictionary: DictionaryType {
        var theElements = [Key: Value]()
        _elements.forEach { key, value in
            if let value = value.value {
                theElements[key] = value
            }
        }
        return theElements
    }

    mutating private func cleanup() {
        _elements = _elements.filter { $0.value.value != nil }
    }
}

extension WeakRefDictionary: ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (Key, Value)...) {
        var theElements = [Key: WeakRef<Value>]()
        elements.forEach { key, value in
            theElements[key] = WeakRef(value: value)
        }
        self._elements = theElements
    }
}

extension WeakRefDictionary: Collection {

    typealias IndexDistance = DictionaryType.IndexDistance
    typealias Indices = DictionaryType.Indices
    typealias Iterator = DictionaryType.Iterator
    typealias SubSequence = DictionaryType.SubSequence
    typealias Index = DictionaryType.Index

    public var startIndex: Index {
        return internalDictionary.startIndex
    }

    public var endIndex: DictionaryType.Index {
        return internalDictionary.endIndex
    }

    public subscript(position: Index) -> Iterator.Element {
        return internalDictionary[position]
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        return internalDictionary[bounds]
    }

    public var indices: Indices {
        return internalDictionary.indices
    }

    public subscript(key: Key) -> Value? {
        get { return internalDictionary[key] }
        set {
            cleanup()
            if let value = newValue {
                _elements[key] = WeakRef(value: value)
            } else {
                _elements[key] = nil
            }
        }
    }

    public func index(after i: Index) -> Index {
        return internalDictionary.index(after: i)
    }

    public func makeIterator() -> DictionaryIterator<Key, Value> {
        return internalDictionary.makeIterator()
    }
}
