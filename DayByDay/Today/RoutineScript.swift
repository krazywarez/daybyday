//
//  RoutineScript.swift
//  DayByDay
//

import Foundation

/// What the Today routine says, line by line, before the weather pick.
nonisolated struct RoutineScript {
    struct Line: Equatable {
        let text: String
        let symbol: String
    }

    let lines: [Line]

    init(date: Date, calendar: Calendar, name: String?, birthday: (month: Int, day: Int)?, picture: DayPictureKind?) {
        func weekday(_ offset: Int) -> DayOfWeek {
            let day = calendar.date(byAdding: .day, value: offset, to: date)!
            return DayOfWeek(rawValue: calendar.component(.weekday, from: day) - 1)!
        }
        let parts = calendar.dateComponents([.month, .day], from: date)
        let month = MonthOfYear(rawValue: parts.month! - 1)!
        let today = weekday(0), yesterday = weekday(-1), tomorrow = weekday(1)

        var lines = [Line(text: name.map { "Hi, \($0)!" } ?? "Hi!", symbol: "sun.max.fill")]
        if let birthday {
            if birthday.month == parts.month, birthday.day == parts.day {
                lines.append(Line(text: "Today is your birthday! Happy birthday!", symbol: "birthday.cake.fill"))
            } else if birthday.month == parts.month {
                lines.append(Line(text: "Your birthday is in \(month.name)!", symbol: "gift.fill"))
            }
        }
        lines.append(Line(text: "Today is \(today.name).", symbol: today.symbol))
        if let picture {
            lines.append(Line(text: "Today is \(picture.name)!", symbol: picture.symbol))
        }
        lines += [
            Line(text: "Yesterday was \(yesterday.name).", symbol: yesterday.symbol),
            Line(text: "Tomorrow is \(tomorrow.name).", symbol: tomorrow.symbol),
            Line(text: "It's \(month.name).", symbol: month.symbol),
            Line(text: "It's \(month.season.name).", symbol: month.season.symbol),
        ]
        self.lines = lines
    }
}
