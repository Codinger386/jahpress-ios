//
//  StationCell.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

class StationCell: UITableViewCell {

    var station: Station?

    var favoriteButtonHandler: ((Station?) -> Void)?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bitrateLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var listenersLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!

    override func prepareForReuse() {
        coverImageView.image = nil
    }

    @IBAction func favoriteButtonPressed(_ sender: Any) {
        favoriteButtonHandler?(station)
    }
}
