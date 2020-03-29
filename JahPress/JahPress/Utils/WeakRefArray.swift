//
//  WeakRefArray.swift
//  RedOne
//
//  Created by Benjamin Ludwig on 25.01.18.
//  Copyright © 2018 Coca-Cola European Partners. All rights reserved.
//

struct WeakRefArray<T: AnyObject> {

    typealias Element = T
    typealias Index = Int

    private var _elements: [WeakRef<Element>] = []

    private var internalArray: [Element] { return _elements.flatMap { $0.value }}

    mutating private func cleanup() {
        _elements = _elements.filter { $0.value != nil }
    }

    mutating func add(element: T) {
        cleanup()
        let weakRef = WeakRef(value: element)
        if !_elements.contains(weakRef) {
            _elements.append(weakRef)
        }
    }

    mutating func remove(element: T) {
        cleanup()
        if let index = _elements.index(where: { weakRef -> Bool in
            return weakRef.value === element
            }) {
            _elements.remove(at: index)
        }
    }
}

extension WeakRefArray: MutableCollection, RandomAccessCollection {

    var startIndex: Int {
        return internalArray.startIndex
    }

    var endIndex: Int {
        return internalArray.endIndex
    }

    subscript(position: Int) -> Element {
        get {
            return internalArray[position]
        }
        set(newValue) {
            cleanup()
            _elements[position] = WeakRef(value: newValue)
        }
    }
}

extension WeakRefArray: ExpressibleByArrayLiteral {

    typealias ArrayLiteralElement = T

    init(arrayLiteral elements: T...) {
        _elements = elements.map { WeakRef(value: $0) }
    }
}
