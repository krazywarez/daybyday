//
//  MonthGrid.swift
//  DayByDay
//

import Foundation

/// A month laid out in Sunday-first weeks.
nonisolated struct MonthGrid: Equatable {
    let year: Int
    let month: Int
    /// Empty cells before the 1st.
    let leadingBlanks: Int
    let days: Int
    private let calendar: Calendar

    init(year: Int, month: Int, calendar: Calendar) {
        self.year = year
        self.month = month
        self.calendar = calendar
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        leadingBlanks = calendar.component(.weekday, from: first) - 1
        days = calendar.range(of: .day, in: .month, for: first)!.count
    }

    /// Blanks, then 1 through the last day.
    var cells: [Int?] { Array(repeating: nil, count: leadingBlanks) + (1...days).map { $0 } }

    /// Whether a later month may be shown: never past `today`'s month.
    func canGoLater(than today: (year: Int, month: Int)) -> Bool {
        (year, month) < (today.year, today.month)
    }

    func shifted(by months: Int) -> MonthGrid {
        let index = year * 12 + (month - 1) + months
        return MonthGrid(year: index / 12, month: index % 12 + 1, calendar: calendar)
    }

    static func == (a: MonthGrid, b: MonthGrid) -> Bool { a.year == b.year && a.month == b.month }
}
