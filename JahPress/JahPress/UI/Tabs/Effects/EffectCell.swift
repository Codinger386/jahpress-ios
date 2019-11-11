//
//  EffectCell.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

class EffectCell: UICollectionViewCell {
    weak var effectView: EffectView! {
        willSet {
            guard newValue != effectView, newValue != nil else { return }
            let contentSubViews = contentView.subviews
            contentSubViews.forEach { $0.removeFromSuperview() }
            contentView.addSubview(newValue)
            newValue.frame = contentView.bounds
            newValue.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
}
