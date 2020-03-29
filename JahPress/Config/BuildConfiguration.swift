//
//  Configuration.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation

enum DevelopmentEnvironment: String {
    case mockdata
	case dev
	case qa
	case prod
}

extension DevelopmentEnvironment: Configurable {

	init(_ value: String) {
		if let instance = DevelopmentEnvironment(rawValue: value.lowercased()) {
			self = instance
		} else {
			self = .dev
		}
	}
}

struct BuildConfiguration {

	private static let dictionary = Bundle.main.infoDictionary!

	// swiftlint:disable force_cast
	/** The current environment. Default is `.dev`
	- seealso: `Environment`
	*/
	static let environemt: DevelopmentEnvironment = {
		let environemtName = (BuildConfiguration.dictionary["ENVIRONMENT"] as! String)
		return DevelopmentEnvironment(environemtName)
	}()

	/// The Logging-Level used for the Logger
	static let logLevel = (BuildConfiguration.dictionary["LOG_LEVEL"] as? String) ?? "none"

	/// The Logging-Destination(s) used by the Logger
	static let logDestinations = ((BuildConfiguration.dictionary["LOG_DESTINATIONS"] as? String) ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "\""))
	static let logURL = ((BuildConfiguration.dictionary["LOG_URL"] as? String) ?? "").trimmingCharacters(in:
		CharacterSet(charactersIn: "\"")).replacingOccurrences(of: "\\", with: "")

	static let logShowLevel = (BuildConfiguration.dictionary["LOG_SHOW_LEVEL"] as? String) == "1"
	static let logShowIdentifier = (BuildConfiguration.dictionary["LOG_SHOW_IDENTIFIER"] as? String) == "1"
	static let logShowFile = BuildConfiguration.dictionary["LOG_SHOW_FILE"] as? String == "1"
	static let logShowLine = BuildConfiguration.dictionary["LOG_SHOW_LINE"] as? String == "1"
	static let logShowFunction = BuildConfiguration.dictionary["LOG_SHOW_FUNCTION"] as? String == "1"
	static let logShowThread = BuildConfiguration.dictionary["LOG_SHOW_THREAD"] as? String == "1"
	static let logShowDate = BuildConfiguration.dictionary["LOG_SHOW_DATE"] as? String == "1"
	static let logShowPictogram = BuildConfiguration.dictionary["LOG_SHOW_PICTOGRAM"] as? String == "1"

    static let shoutcastAPIKey = BuildConfiguration.dictionary["SHOUTCAST_API"] as! String

    static let appStoreID: String = BuildConfiguration.dictionary["APP_STORE_ID"] as! String

    static let adMobAppId: String = BuildConfiguration.dictionary["AD_MOB_APP_ID"] as! String
    static let adMobBannerId: String = BuildConfiguration.dictionary["AD_MOB_BANNER_ID"] as! String

    static let fireBaseId: String = BuildConfiguration.dictionary["FIRE_BASE_ID"] as! String

    static let appsFlyerId: String = BuildConfiguration.dictionary["APPS_FLYER_ID"] as! String
}

/** Types that are configurable by a value from the `Configuration`, should implement this protocol
*/
protocol Configurable: ExpressibleByStringLiteral {
	/** Initialize the type with a string-value e.q. from the `Configuration`
	- parameter value: A string-value
	*/
	init(_ value: String)
}

extension Configurable {
	public typealias StringLiteralType = String

	public init(stringLiteral value: Self.StringLiteralType) {
		self.init(String(describing: value))
	}
}
