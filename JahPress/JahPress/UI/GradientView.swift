//
//  GradientView.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 24.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

enum GradientViewType {
    case vertical
    case horizontal
}

class GradientView: UIView {

    override class var layerClass: AnyClass { return CAGradientLayer.self }

    // swiftlint:disable:next force_cast
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    init(frame: CGRect, colors: [UIColor], type: GradientViewType = .vertical) {
        super.init(frame: frame)

        gradientLayer.colors = colors.map({ color -> CGColor in
            return color.cgColor
        })

        var steps = [NSNumber]()
        colors.enumerated().forEach { index, _ in
            let value: Double = Double(index) * (1.0 / Double(colors.count - 1))
            steps.append(NSNumber(value: value))
        }
        gradientLayer.locations = steps
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
