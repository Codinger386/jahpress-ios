//
//  Logger.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//
import Foundation

protocol Logger {

	init(subsystem: String, category: String)

	func logVerbose(_ message: Any, file: StaticString, function: StaticString, line: Int)
	func logDebug(_ message: Any, file: StaticString, function: StaticString, line: Int)
	func logInfo(_ message: Any, file: StaticString, function: StaticString, line: Int)
	func logWarning(_ message: Any, file: StaticString, function: StaticString, line: Int)
	func logError(_ message: Any, file: StaticString, function: StaticString, line: Int)
	func logSevere(_ message: Any, file: StaticString, function: StaticString, line: Int)
}

extension Logger {

	func verbose(_ message: Any,
	             file: StaticString = #file,
	             function: StaticString = #function,
	             line: Int = #line) {
		self.logVerbose(message, file: file, function: function, line: line)
	}

	func debug(_ message: Any,
	           file: StaticString = #file,
	           function: StaticString = #function,
	           line: Int = #line) {
		self.logDebug(message, file: file, function: function, line: line)
	}

	func info(_ message: Any,
	          file: StaticString = #file,
	          function: StaticString = #function,
	          line: Int = #line) {
		self.logInfo(message, file: file, function: function, line: line)
	}

	func warning(_ message: Any,
	             file: StaticString = #file,
	             function: StaticString = #function,
	             line: Int = #line) {
		self.logWarning(message, file: file, function: function, line: line)
	}

	func error(_ message: Any,
	           file: StaticString = #file,
	           function: StaticString = #function,
	           line: Int = #line) {
		self.logError(message, file: file, function: function, line: line)
	}

	func severe(_ message: Any,
	            file: StaticString = #file,
	            function: StaticString = #function,
	            line: Int = #line) {
		self.logSevere(message, file: file, function: function, line: line)
	}
}
