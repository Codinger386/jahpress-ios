//
//  FormattingExtensions.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import Foundation

private let standardTimeZone: String = "GMT"
private let standardDateFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
private let monthDayFormat: String = "MMMM dd"

extension Formatter {
    static let standardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = standardDateFormat
        formatter.timeZone = TimeZone(identifier: standardTimeZone)
        return formatter
    }()

    static let monthDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = monthDayFormat
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static let localTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static let localDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let standardNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()

    static let standardNumberWithOneDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()

    static let standardPercentageNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .percent
        return formatter
    }()
}

// MARK: Decimal

extension Decimal {
    func standardFormattedPercentageString() -> String {
        return Formatter.standardPercentageNumberFormatter.string(from: NSDecimalNumber(decimal: self)) ?? ""
    }
    func standardFormattedNumberString(enforceDecimalPlace: Bool = false) -> String {
        return (enforceDecimalPlace ? Formatter.standardNumberWithOneDecimalFormatter : Formatter.standardNumberFormatter).string(from: NSDecimalNumber(decimal: self)) ?? ""
    }
}

// MARK: Date

extension Date {
    func standardFormattedString() -> String {
        return Formatter.standardDateFormatter.string(from: self)
    }

    func monthDayFormattedString() -> String {
        return Formatter.monthDayDateFormatter.string(from: self)
    }

    func localTimeFormattedString() -> String {
        return Formatter.localTimeFormatter.string(from: self)
    }

    func localDateTimeFormattedString() -> String {
        return Formatter.localDateTimeFormatter.string(from: self)
    }
}

// MARK: String

extension String {
    func dateFromStandardFormattedString() -> Date? {
        return Formatter.standardDateFormatter.date(from: self)
    }
}
