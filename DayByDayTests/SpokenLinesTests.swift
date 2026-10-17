import Foundation
import Testing
@testable import DayByDay

struct SpokenLinesTests {
    typealias Topic = DayByDay.Category
    static let all = SpokenLines.all

    func covered(_ text: String) -> Bool {
        SpokenText.sentences(text).allSatisfy { Self.all.contains($0) }
    }

    @Test func onlyListedNamesAreSpoken() {
        #expect(Set(Self.all.filter { $0.hasPrefix("Hi, ") }) == Set(Lines.spokenNames.map { "Hi, \($0)!" }))
        #expect(Lines.spokenNames.count == 17)
        #expect(Self.all.contains(Lines.greeting))
    }

    @Test func catalogSize() {
        #expect((2_000...4_000).contains(Self.all.count), "\(Self.all.count)")
    }

    /// Seeds the catalog did not use: every prompt and correction a game produces is covered.
    @Test func roundGamesAreCovered() {
        var rng = SeededGenerator(seed: 900)
        for c in Topic.gridCases {
            for game in c.games where game.usesRound {
                let source = c.questionSource(for: game)
                var previous: QuizItem?
                for i in 0..<2_000 {
                    let q = source.next(correctCount: i % 5, excluding: previous, using: &rng)
                    #expect(covered(q.prompt), "\(c) \(game): \(q.prompt)")
                    for choice in q.choices where choice != q.answer {
                        #expect(covered(q.correction(for: choice)), "\(c) \(game): \(q.correction(for: choice))")
                    }
                    previous = q.answer
                }
            }
        }
    }

    @Test func routineIsCovered() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var rng = SeededGenerator(seed: 901)
        var day = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 9))!
        for _ in 0..<365 {
            let birthday = (month: Int.random(in: 1...12, using: &rng), day: Int.random(in: 1...28, using: &rng))
            let picture = DayPictureKind.allCases.randomElement(using: &rng)
            for line in RoutineScript(date: day, calendar: calendar, name: "Maya", birthday: birthday, picture: picture).lines {
                #expect(covered(line.spoken), "\(line.spoken)")
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        for w in TodayRoutineView.weathers { #expect(covered(Lines.sticker(w))) }
        #expect(covered(Lines.weatherQuestion))
    }

    @Test func otherGamesAreCovered() {
        var rng = SeededGenerator(seed: 902)
        var train = SequencePuzzle.weekTrain(using: &rng)
        while let step = train.current {
            #expect(covered(step.prompt)); #expect(covered(train.correction()))
            _ = train.place(step.answer)
        }
        #expect(covered(train.summary))
        for today in DayOfWeek.allCases {
            var p = SequencePuzzle.yesterdayTomorrow(today: today, using: &rng)
            while let step = p.current {
                #expect(covered(step.prompt)); #expect(covered(p.correction()))
                _ = p.place(step.answer)
            }
            #expect(covered(p.summary))
        }
        for food in LearnFood.allCases {
            #expect(covered(SortRound.question(for: food)))
            #expect(covered("\(SortRound.fact(for: food)) Try again!"))
        }
        for part in LearnBodyPart.allCases { #expect(covered(part.command)) }
        for thing in CountingRound.things {
            #expect(covered(Lines.countPrompt(thing)))
            for n in 1...10 {
                let r = CountingRound(target: n, thing: thing, using: &rng)
                #expect(covered(r.summary()))
                #expect(covered(LearnNumber(rawValue: n)!.name))
            }
        }
        for item in Topic.shapes.quizItems + Topic.alphabet.quizItems {
            #expect(covered(Lines.tracePrompt(item)))
            #expect(covered(Lines.traceSuccess(item)))
            #expect(covered(Lines.traceMiss(item)))
        }
        for m in MonthOfYear.allCases { #expect(covered(YearWheel.line(for: m))) }
        #expect(covered(Lines.spinPrompt))
        for p in PraisePhrases.all { #expect(covered(p)) }
        for g in Game.allCases { #expect(covered(g.title)) }
        for line in [Lines.lookAndListen, Lines.whoIsPlaying, Lines.youDidIt, Lines.itsRaining] {
            #expect(covered(line))
        }
    }

    @Test func cardsAndCalendarAreCovered() {
        for animal in LearnAnimal.allCases { #expect(covered(animal.cardLine)) }
        for letter in LearnLetter.allCases { #expect(covered(letter.cardLine)) }
        for day in DayOfWeek.allCases {
            #expect(covered(Lines.dayCard(day, picture: nil)))
            for kind in DayPictureKind.allCases { #expect(covered(Lines.dayCard(day, picture: kind))) }
        }
        for c in Topic.gridCases { for item in c.quizItems { #expect(covered(item.name)) } }
        for color in LearnColor.allCases { #expect(covered(color.name)) }
        for (i, month) in MonthOfYear.allCases.enumerated() {
            for day in 1...ProfileStore.daysInMonth[i] {
                #expect(covered(Lines.calendarDay(month, day, weather: nil)))
                for w in TodayRoutineView.weathers { #expect(covered(Lines.calendarDay(month, day, weather: w))) }
            }
        }
    }
}
