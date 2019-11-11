//
//  ROLogger+XCGLogger.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation
import XCGLogger

extension ROLogger {

	static func loggerImpl() -> XCGLogger {
		let logger = XCGLogger()
		logger.destinations = []
		let level = LogLevel(BuildConfiguration.logLevel)
		let destinations = LogDestination(BuildConfiguration.logDestinations)

		if destinations.contains(.console) {
			let consoleDestination = ConsoleDestination(identifier: logger.identifier+".destination.console")
			configureDestination(consoleDestination, level: level)
			logger.add(destination: consoleDestination)
		}

		if destinations.contains(.system) {
			let systemDestination = AppleSystemLogDestination(identifier: logger.identifier+".destination.system")
			configureDestination(systemDestination, level: level)
			logger.add(destination: systemDestination)
		}

		if destinations.contains(.url) {
			if let filePath = URL(string: BuildConfiguration.logURL)?.path {
				let fileDestination = FileDestination(writeToFile: filePath, identifier: logger.identifier+".destination.file")
				configureDestination(fileDestination, level: level)
				logger.add(destination: fileDestination)
			}
		}

		if BuildConfiguration.logShowPictogram {
			logger.levelDescriptions[.verbose] = "📓"
			logger.levelDescriptions[.debug] = "🐞"
			logger.levelDescriptions[.info] = "ℹ️"
			logger.levelDescriptions[.warning] = "⚠️"
			logger.levelDescriptions[.error] = "‼️"
			logger.levelDescriptions[.severe] = "💣"
		}
		return logger
	}

	private static func configureDestination(_ destination: BaseDestination, level: LogLevel) {
		destination.outputLevel = level.xcgLogLevel
		destination.showLogIdentifier = BuildConfiguration.logShowIdentifier
		destination.showFunctionName = BuildConfiguration.logShowFunction
		destination.showThreadName = BuildConfiguration.logShowThread
		destination.showLevel = BuildConfiguration.logShowLevel
		destination.showFileName = BuildConfiguration.logShowFile
		destination.showLineNumber = BuildConfiguration.logShowLine
		destination.showDate = BuildConfiguration.logShowDate
	}
}

/// Maps `Logger` log-levels to `XCGLogger` levels
private extension LogLevel {
	var xcgLogLevel: XCGLogger.Level {
		switch self {
		case .verbose:
			return XCGLogger.Level.verbose
		case .info:
			return XCGLogger.Level.info
		case .debug:
			return XCGLogger.Level.debug
		case .warning:
			return XCGLogger.Level.warning
		case .error:
			return XCGLogger.Level.error
		case .severe:
			return XCGLogger.Level.severe
		case .none:
			return XCGLogger.Level.none
		}
	}
}

/** Available log-levels for the `Logger`
*/
private enum LogLevel: String {
	/// Everything
	case verbose

	/// Messages that help to find bugs
	case debug

	///	Messages that show what the App is currently doing
	case info

	/// Messages that describe a problem that can be resolved without user interaction
	/// e.g. A certain server is not available but there is an alternative
	case warning

	/// Messages that describe a problem that can not be resolved without user interaction
	/// e.g. Neither the normal nor fallback server can be reached
	case error

	/// Messages that prevent further operation.
	/// e.g. Out of memory
	case severe

	/// No messages are logged
	case none
}

/// Creates LogLevel directly from `Configuration` values
extension LogLevel: Configurable {
	init(_ value: String) {
		if let instance = LogLevel(rawValue: value.lowercased()) {
			self = instance
		} else {
			self = .none
		}
	}
}

/// Available destinations
private struct LogDestination: OptionSet {
	/// Logs to Xcode console
	static let console = LogDestination(rawValue: 1 << 0)

	/// Logs to Xcode and system console
	static let system = LogDestination(rawValue: 1 << 1)

	/// Logs to an URL. Currently only file URLs are supported
	static let url = LogDestination(rawValue: 1 << 2)

	public let rawValue: Int
}

/// Creates LogDestinations directly from `Configuration` values
extension LogDestination: Configurable {
	init(_ value: String) {
		self = LogDestination(value.split(separator: " ").map {
			switch $0.lowercased() {
			case "url":
				return .url
			case "system":
				return .system
			case "console":
				return .console
			default:
				return .console
			}
		})
	}
}
