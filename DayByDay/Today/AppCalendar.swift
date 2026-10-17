//
//  AppCalendar.swift
//  DayByDay
//

import Foundation

/// The calendar for every date the app shows or stores: Gregorian, weeks
/// starting on Sunday, in the device's time zone, whatever calendar the
/// device itself is set to.
nonisolated enum AppCalendar {
    static var current: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 1
        return calendar
    }
}
