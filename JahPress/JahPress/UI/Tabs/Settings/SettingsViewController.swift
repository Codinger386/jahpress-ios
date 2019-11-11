//
//  SettingsViewController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 24.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, AppDependencyInjectable {

    var dependencies: AppDependencies!

    override func viewDidLoad() {

    }

    @IBAction func shareButton(_ sender: Any) {
        // https://itunes.apple.com/app/jahpress/id1334640352?mt=8
        guard let url = URL(string : "https://itunes.apple.com/app/id" + BuildConfiguration.appStoreID + "?mt=8") else {
            return
        }

        let objectsToShare: [Any] = ["JahPress", url]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }

    @IBAction func rateButton(_ sender: Any) {
        guard let url = URL(string : "itms-apps://itunes.apple.com/app/id" + BuildConfiguration.appStoreID + "?mt=8") else {
            return
        }
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

    @IBAction func shoutcastButton(_ sender: Any) {
        guard let url = URL(string: "http://www.shoutcast.com") else { return }
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

    @IBAction func privacyPolicyButton(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "PrivacyPolicyViewController") else { return }
        present(vc, animated: true, completion: nil)
    }

    @IBAction func disclaimerButton(_ sender: Any) {
        self.present(DisclaimerPopup.popUp(), animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
