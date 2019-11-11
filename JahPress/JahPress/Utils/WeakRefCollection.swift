//
//  WeakRefCollection.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.01.18.
//  Copyright © 2018 Benjamin Ludwig. All rights reserved.
//

import UIKit

struct WeakRefCollection<Element: Hashable> where Element: AnyObject {

    fileprivate var contents: [WeakRef<Element>] = []

    var count: Int {
        return contents.compactMap { $0.value }.count
    }

    init() { }

    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        for element in sequence {
            add(element)
        }
    }

    mutating func add(_ member: Element) {
        cleanup()
        contents.append(WeakRef(value: member))
    }

    mutating func cleanup() {
        contents = contents.filter { $0.value != nil }
    }
}

extension WeakRefCollection: Sequence {

    typealias Iterator = AnyIterator<Element>

    func makeIterator() -> Iterator {

        var iterator = contents.compactMap { $0.value }.makeIterator()

        return AnyIterator {
            return iterator.next()
        }
    }
}

extension WeakRefCollection: Collection {

    typealias Index = Int

    var startIndex: Index {
        return contents.filter { $0.value != nil }.startIndex
    }

    var endIndex: Index {
        return contents.filter { $0.value != nil }.endIndex
    }

    subscript (position: Index) -> Iterator.Element {
        get {
            let element = contents.filter { $0.value != nil }[position]
            return element.value!
        }
        set {
            cleanup()
            contents[position] = WeakRef(value: newValue)
        }
    }

    func index(after i: Index) -> Index {
        return contents.filter { $0.value != nil }.index(after: i)
    }
}
