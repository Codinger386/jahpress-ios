//
//  UserReadableError.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation

protocol UserReadableError: Error {
    var displayTitle: String { get }
    var displayMessage: String { get }
}

extension UserReadableError {
    var displayTitle: String {
        return type(of: self).defaultTitle
    }

    var displayMessage: String {
        let comps: [String?] = [self.localizedDescription, (self as? LocalizedError)?.recoverySuggestion]
        let body: String = comps.compactMap({$0}).joined(separator: " ")

        return body
    }
}

extension Error {
    static var defaultTitle: String {
        return "Error"
    }
}
