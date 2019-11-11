//
//  Effect.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

struct Effect: Codable {
    var order: Int
    var type: String
    var title: String
    var file: String

    init?(dict: [String: Any]) {
        guard let order = dict["order"] as? Int else { return nil }
        guard let type = dict["type"] as? String else { return nil }
        guard let title = dict["title"] as? String else { return nil }
        guard let file = dict["file"] as? String else { return nil }

        self.order = order
        self.type = type
        self.title = title
        self.file = file
    }
}
