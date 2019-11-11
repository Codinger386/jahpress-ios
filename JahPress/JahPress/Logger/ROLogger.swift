//
//  ROLogger.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation
import XCGLogger

public struct ROLogger: Logger {

	private let logger: XCGLogger
	private let userInfo: [String: String]

	init(subsystem: String = Bundle.main.bundleIdentifier ?? "de.jahpress.ios",
	     category: String = "Default") {

		self.logger = ROLogger.loggerImpl()
		self.logger.identifier = subsystem
		self.userInfo = ["Category" : category]
	}

	public func logVerbose(_ message: Any, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
		logger.verbose(message, functionName: function, fileName: file, lineNumber: line, userInfo: userInfo)
	}

	public func logDebug(_ message: Any, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
		logger.debug(message, functionName: function, fileName: file, lineNumber: line, userInfo: userInfo)
	}

	public func logInfo(_ message: Any, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
		logger.info(message, functionName: function, fileName: file, lineNumber: line, userInfo: userInfo)
	}

	public func logWarning(_ message: Any, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
		logger.warning(message, functionName: function, fileName: file, lineNumber: line, userInfo: userInfo)
	}

	public func logError(_ message: Any, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
		logger.error(message, functionName: function, fileName: file, lineNumber: line, userInfo: userInfo)
	}

	public func logSevere(_ message: Any, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
		logger.severe(message, functionName: function, fileName: file, lineNumber: line, userInfo: userInfo)
	}
}
