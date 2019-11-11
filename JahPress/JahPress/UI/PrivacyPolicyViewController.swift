//
//  PrivacyPolicyViewController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 04.11.18.
//  Copyright © 2018 Benjamin Ludwig. All rights reserved.
//

import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!

    @IBAction func accept(_ sender: Any) {
        JahUserDefaults.privacyPolicyAccepted = true
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        guard let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "html") else { return }
        webView.loadFileURL(url, allowingReadAccessTo: url)
        webView.navigationDelegate = self
    }
}

extension PrivacyPolicyViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                print(url)
                print("Redirected to browser. No need to open it locally")
                decisionHandler(.cancel)
            } else {
                print("Open it locally")
                decisionHandler(.allow)
            }
        } else {
            print("not a user click")
            decisionHandler(.allow)
        }
    }
}
