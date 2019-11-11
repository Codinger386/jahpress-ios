//
//  WeakRef.swift
//  RedOne
//
//  Created by Benjamin Ludwig on 25.01.18.
//  Copyright © 2018 Coca-Cola European Partners. All rights reserved.
//

class WeakRef<T: AnyObject>: Equatable {

    private(set) weak var value: T?

    init(value: T) {
        self.value = value
    }

    static func == (lhs: WeakRef, rhs: WeakRef) -> Bool {
        return lhs.value === rhs.value
    }
}
