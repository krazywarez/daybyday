//
//  Lines.swift
//  DayByDay
//

import Foundation

/// Spoken lines that views build, kept here so the views and the voice clip
/// catalog (`SpokenLines`) produce exactly the same text.
nonisolated enum Lines {
    static let greeting = "Hi there!"

    /// Names with a recorded greeting. Any other name is greeted without it.
    static let spokenNames = [
        "Gianna", "Gigi", "Ashlynn", "Ash", "Olive", "Ollie", "Elijah", "Arthur", "Noah",
        "Thad", "Thadeus", "Izzy", "Isabella", "Sam", "Sammy", "Frankie", "Franklin",
    ]

    static func greeting(for name: String?) -> String {
        let typed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let match = spokenNames.first(where: { $0.caseInsensitiveCompare(typed) == .orderedSame }) else {
            return greeting
        }
        return "Hi, \(match)!"
    }
    static let whoIsPlaying = "Who's playing?"
    static let youDidIt = "You did it!"
    static let lookAndListen = "Look and listen"
    static let spinPrompt = "Spin the wheel! Or tap a month."
    static let weatherQuestion = "What's the weather like today?"
    static let itsRaining = "It's raining!"

    /// Weathers a child can pick for a sticker.
    static let stickerWeathers: [LearnWeather] = [.sunny, .cloudy, .rainy, .snowy, .windy]

    static func sticker(_ weather: LearnWeather) -> String {
        "It's \(weather.name.lowercased()) today! Here's your sticker!"
    }

    static func calendarDay(_ month: MonthOfYear, _ day: Int, weather: LearnWeather?) -> String {
        let date = "\(month.name) \(ordinal(day))"
        return weather.map { "On \(date), it was \($0.name.lowercased())." } ?? "\(date)."
    }

    /// 1st, 2nd, 3rd, 4th, …, 11th, 12th, 13th, 21st, …
    static func ordinal(_ n: Int) -> String {
        let suffix = (11...13).contains(n % 100) ? "th" : ["th", "st", "nd", "rd"][n % 10 < 4 ? n % 10 : 0]
        return "\(n)\(suffix)"
    }

    static func dayCard(_ day: DayOfWeek, picture: DayPictureKind?) -> String {
        picture.map { "\(day.name). It's \($0.name)!" } ?? day.name
    }

    static func countPrompt(_ thing: CountingRound.Thing) -> String {
        "Tap each \(thing.singular) to count."
    }

    /// "the letter a" or "the circle".
    static func traceLabel(_ item: QuizItem) -> String {
        item.category == .alphabet ? "the letter \(item.name)" : "the \(item.name.lowercased())"
    }

    static func tracePrompt(_ item: QuizItem) -> String {
        "Trace \(traceLabel(item)) with your finger."
    }

    static func traceSuccess(_ item: QuizItem) -> String { "You traced \(traceLabel(item))!" }

    static func traceMiss(_ item: QuizItem) -> String { "Stay on \(traceLabel(item)). Let's try again." }
}
