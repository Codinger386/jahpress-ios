//
//  ErrorReporter.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

struct ErrorReporter: ErrorReporterProtocol {

    @discardableResult
    func reportError(
        error: Error,
        sourceViewController: UIViewController? = nil,
        retryHandler: ErrorReporterRetryHandler? = nil,
        okHandler: ErrorReporterOkHandler? = nil) -> UIAlertController {
        var title: String
        var message: String
        if let error = error as? UserReadableError {
            title = error.displayTitle
            message = error.displayMessage
        } else {
            title = type(of: error).defaultTitle
            message = error.localizedDescription
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: okHandler)
        alert.addAction(okAction)

        if let handler = retryHandler {
            let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
                handler()
            }
            alert.addAction(retryAction)
        }

        if let vc = sourceViewController {
            vc.present(alert, animated: true, completion: nil)
        } else {
            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        }

        return alert
    }
}
