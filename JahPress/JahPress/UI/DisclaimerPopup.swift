//
//  DisclaimerPopup.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 31.01.18.
//  Copyright © 2018 Benjamin Ludwig. All rights reserved.
//

import UIKit

class YoMama: UIView {

}

class DisclaimerPopup {

    static let disclaimer =
        """
        All radio streams available in this app are provided bei SHOUTcast (www.shoutcast.com)
        and we are very grateful for their work!

        However, we cannot guarantee for the reliability of the streams. Also we are not responsible for the content.

        If you are unhappy with the quality or the content of a radio stream, please provide feedback directly to SHOUTcast.
        """

    static func popUp() -> UIAlertController {

        let alertController = UIAlertController(title: "Disclaimer", message: DisclaimerPopup.disclaimer, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok, got it!", style: .default, handler: nil)
        let shoutcastAction = UIAlertAction(title: "Visit SHOUTcast", style: .default) { _ in
            guard let url = URL(string: "http://www.shoutcast.com") else { return }
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
        alertController.addAction(okAction)
        alertController.addAction(shoutcastAction)
        return alertController
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
