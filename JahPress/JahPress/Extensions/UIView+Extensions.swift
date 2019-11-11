//
//  UIView+Extensions.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

extension UIView {

    @IBInspectable
    var cornerRadius: CGFloat {
        get {return self.layer.cornerRadius}
        set {
            self.layer.cornerRadius = newValue
        }
    }

    @IBInspectable
    var backgroundOpacity: CGFloat {
        get {
            if let color = backgroundColor {
                var white: CGFloat = 0
                var alpha: CGFloat = 0
                color.getWhite(&white, alpha: &alpha)
                return alpha
            }
            return 1.0
        }
        set {
            guard let color = backgroundColor else {return}
            backgroundColor = color.withAlphaComponent(newValue)
        }
    }

    func rotate(by angle: CGFloat, around rotationCenter: CGPoint) {
        transform = CGAffineTransform(translationX: rotationCenter.x-center.x, y: rotationCenter.y-center.y)
            .rotated(by: angle * .pi / 180)
            .translatedBy(x: -rotationCenter.x+center.x, y: -rotationCenter.y+center.y)
    }
}

extension UIView {
	func removeAllSubviews() {
		self.subviews.forEach { $0.removeFromSuperview() }
	}

    func startFlashing(withInterval interval: Double) {
        let flashing = CABasicAnimation(keyPath: "opacity")
        flashing.fromValue = 1.0
        flashing.toValue = 0.0
        flashing.duration = interval
        flashing.autoreverses = true
        flashing.isRemovedOnCompletion = false
        flashing.repeatCount = .infinity
        self.layer.add(flashing, forKey: "UIView+Extensions_flashing")
    }

    func stopFlashing() {
        layer.removeAnimation(forKey: "UIView+Extensions_flashing")
    }
}
