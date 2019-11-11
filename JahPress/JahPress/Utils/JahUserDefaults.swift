//
//  JahUserDefaults.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.01.18.
//  Copyright © 2018 Benjamin Ludwig. All rights reserved.
//

import Foundation

let userDefaultsFavoritesKey = "UserDefaults.Keys.Favorites"
let userDefaultsDisclaimerShownKey = "UserDefaults.Keys.DisclaimerShown"
let userDefaultsPrivacyPolicyAcceptedKey = "UserDefaults.Keys.PrivacyPolicyAccepted"

class JahUserDefaults {

    static var favorites: [String] = []

    static var disclaimerShown: Bool {
        get { return UserDefaults.standard.bool(forKey: userDefaultsDisclaimerShownKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsDisclaimerShownKey)
            UserDefaults.standard.synchronize()
        }
    }

    static var privacyPolicyAccepted: Bool {
        get { return UserDefaults.standard.bool(forKey: userDefaultsPrivacyPolicyAcceptedKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsPrivacyPolicyAcceptedKey)
            UserDefaults.standard.synchronize()
        }
    }

    static func loadDefaults() {
        if let list = UserDefaults.standard.object(forKey: userDefaultsFavoritesKey) as? [String] {
            favorites = list
        } else {
            favorites = []
        }
    }

    static func add(favoriteWith stationId: String) {
        guard !favorites.contains(stationId) else { return }
        favorites.append(stationId)
        UserDefaults.standard.set(favorites, forKey: userDefaultsFavoritesKey)
        UserDefaults.standard.synchronize()
    }

    static func remove(favoriteWith stationId: String) {
        guard let index = favorites.index(of: stationId) else { return }
        favorites.remove(at: index)
        UserDefaults.standard.set(favorites, forKey: userDefaultsFavoritesKey)
        UserDefaults.standard.synchronize()
    }

    static func contains(favoriteWith stationId: String) -> Bool {
        return favorites.contains(stationId)
    }
}
