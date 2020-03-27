//
//  FloatingLabel.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.01.18.
//  Copyright © 2018 Benjamin Ludwig. All rights reserved.
//

import UIKit
import Anchorage

class FloatingLabel: UIView {

    private static let AnimationIdentifier = "FloatingLabel.AnimationIdentifier"

    private var label: UILabel!

    var text: String? {
        get {
            return label.text
        }
        set {
            label.layer.removeAnimation(forKey: FloatingLabel.AnimationIdentifier)
            label.frame = bounds
            label.text = newValue
            guard let text = newValue else { return }
            let textRect = (text as NSString).size(withAttributes: [NSAttributedString.Key.font: label.font])
            if textRect.width > frame.size.width {
                label.frame = CGRect(x: 0, y: 0, width: textRect.width, height: bounds.height)
                let floating = CABasicAnimation(keyPath: "transform.translation.x")
                floating.fromValue = bounds.width
                floating.toValue = -textRect.width
                floating.repeatCount = .infinity
                floating.duration = Double(label.frame.size.width / bounds.width) * 6.0
                label.layer.add(floating, forKey: FloatingLabel.AnimationIdentifier)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    var backgroundListener: Any?
    var activeListener: Any?

    func setupUI() {
        label = UILabel(frame: self.bounds)
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(label)
        clipsToBounds = true
        backgroundColor = UIColor.clear

        backgroundListener = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.label.layer.removeAnimation(forKey: FloatingLabel.AnimationIdentifier)
        }

        activeListener = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard self != nil else { return }
            self!.text = self!.label.text
        }
    }

    deinit {
        guard let backgroundListener = backgroundListener, let activeListener = activeListener else { return }
        NotificationCenter.default.removeObserver(backgroundListener)
        NotificationCenter.default.removeObserver(activeListener)
    }
}
