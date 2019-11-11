//
//  ErrorReporterProtocol.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import Foundation

typealias ErrorReporterRetryHandler = () -> Void
typealias ErrorReporterOkHandler = (UIAlertAction) -> Void

protocol ErrorReporterProtocol {
    @discardableResult
    func reportError(error: Error, sourceViewController: UIViewController?, retryHandler: ErrorReporterRetryHandler?, okHandler: ErrorReporterOkHandler?) -> UIAlertController
}
