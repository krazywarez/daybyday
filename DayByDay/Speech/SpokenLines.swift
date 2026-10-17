//
//  SpokenLines.swift
//  DayByDay
//

import Foundation

/// Every sentence the app can speak, built from the same producers the games
/// and screens use. The voice clips are rendered from this list.
nonisolated enum SpokenLines {
    static let all: Set<String> = {
        var lines: [String] = []

        // Cards, hub buttons, picker, finish screen.
        for c in Category.gridCases { lines += c.quizItems.map(\.name) }
        lines += LearnColor.allCases.map(\.name)
        lines += LearnAnimal.allCases.map(\.cardLine)
        lines += LearnLetter.allCases.map(\.cardLine)
        for day in DayOfWeek.allCases {
            lines.append(Lines.dayCard(day, picture: nil))
            lines += DayPictureKind.allCases.map { Lines.dayCard(day, picture: $0) }
        }
        lines += Game.allCases.map(\.title)
        lines += [Lines.lookAndListen, Lines.whoIsPlaying, Lines.greeting, Lines.youDidIt,
                  Lines.spinPrompt, Lines.weatherQuestion, Lines.itsRaining]
        lines += Lines.spokenNames.map { Lines.greeting(for: $0) }
        lines += PraisePhrases.all

        // Question rounds: prompts and every correction.
        var rng = LineSeed(state: 1)
        for c in Category.gridCases {
            for game in c.games where game.usesRound {
                let source = c.questionSource(for: game)
                var previous: QuizItem?
                for i in 0..<3_000 {
                    let q = source.next(correctCount: i % 5, excluding: previous, using: &rng)
                    lines.append(q.prompt)
                    for choice in q.choices where choice != q.answer { lines.append(q.correction(for: choice)) }
                    previous = q.answer
                }
            }
        }

        // Placement, sorting, moves, counting, tracing, year wheel.
        var puzzles = [SequencePuzzle.weekTrain(using: &rng)]
        puzzles += DayOfWeek.allCases.map { SequencePuzzle.yesterdayTomorrow(today: $0, using: &rng) }
        for var p in puzzles {
            while let step = p.current {
                lines += [step.prompt, p.correction()]
                _ = p.place(step.answer)
            }
            lines.append(p.summary)
        }
        for food in LearnFood.allCases {
            lines += [SortRound.question(for: food), "\(SortRound.fact(for: food)) Try again!"]
        }
        lines += LearnBodyPart.allCases.map(\.command)
        for thing in CountingRound.things {
            lines.append(Lines.countPrompt(thing))
            for n in 1...10 {
                lines.append(CountingRound(target: n, thing: thing, using: &rng).summary())
                lines.append(LearnNumber(rawValue: n)!.name)
            }
        }
        for item in Category.shapes.quizItems + Category.alphabet.quizItems {
            lines += [Lines.tracePrompt(item), Lines.traceSuccess(item), Lines.traceMiss(item)]
        }
        lines += MonthOfYear.allCases.map(YearWheel.line)

        // Today routine over a leap year, with every birthday and picture line.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var date = calendar.date(from: DateComponents(year: 2028, month: 1, day: 1, hour: 9))!
        for i in 0..<366 {
            let parts = calendar.dateComponents([.month, .day], from: date)
            let picture = DayPictureKind.allCases[i % DayPictureKind.allCases.count]
            for birthday in [(month: parts.month!, day: parts.day!), (month: parts.month!, day: parts.day! % 28 + 1)] {
                lines += RoutineScript(date: date, calendar: calendar, name: nil, birthday: birthday,
                                       picture: picture).lines.map(\.spoken)
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        lines += Lines.stickerWeathers.map(Lines.sticker)

        // Sticker calendar: every date, with and without each sticker weather.
        let days = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        for (i, month) in MonthOfYear.allCases.enumerated() {
            for day in 1...days[i] {
                lines.append(Lines.calendarDay(month, day, weather: nil))
                lines += Lines.stickerWeathers.map { Lines.calendarDay(month, day, weather: $0) }
            }
        }

        return Set(lines.flatMap(SpokenText.sentences))
    }()
}

/// SplitMix64, so the catalog is the same on every run.
nonisolated private struct LineSeed: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
