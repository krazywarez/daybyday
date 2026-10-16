import Testing
@testable import DayByDay

struct SequencePuzzleTests {
    let days = DayByDay.Category.days

    func day(_ d: DayOfWeek) -> QuizItem { days.item(d) }

    func train(seed: UInt64 = 41) -> SequencePuzzle {
        var rng = SeededGenerator(seed: seed)
        return .weekTrain(using: &rng)
    }

    @Test func trainOrder() {
        let p = train()
        #expect(p.steps.map(\.answer) == DayOfWeek.allCases.map(day))
        #expect(Set(p.pool) == Set(DayOfWeek.allCases.map(day)))
        #expect(p.pool.count == 7)
        #expect(p.steps[0].prompt == "Which day comes first?")
        #expect(p.slotLabels == nil)
    }

    @Test(arguments: DayOfWeek.allCases) func yesterdayTomorrowWraps(_ today: DayOfWeek) {
        var rng = SeededGenerator(seed: 42)
        let p = SequencePuzzle.yesterdayTomorrow(today: today, using: &rng)
        let i = today.rawValue
        let expected = [(i + 6) % 7, i, (i + 1) % 7].map { day(DayOfWeek(rawValue: $0)!) }
        #expect(p.steps.map(\.answer) == expected)
        #expect(p.pool.count == 4)
        #expect(Set(p.pool).count == 4)
        #expect(Set(expected).isSubset(of: Set(p.pool)))
        #expect(p.slotLabels == ["Yesterday", "Today", "Tomorrow"])
        #expect(p.steps.map(\.prompt) == ["Which day was yesterday?", "Which day is today?", "Which day will it be tomorrow?"])
    }

    @Test func correctPlacementAdvances() {
        var p = train()
        #expect(p.place(day(.sunday)) == .correct)
        #expect(p.placed == [day(.sunday)])
        #expect(p.current?.prompt == "What comes after Sunday?")
    }

    @Test func wrongPlacementWaits() {
        var p = train()
        #expect(p.place(day(.tuesday)) == .incorrect(correctName: "Sunday"))
        #expect(p.place(day(.sunday)) == .ignored)
        p.resume()
        #expect(p.place(day(.sunday)) == .correct)
    }

    @Test func placedCardIgnored() {
        var p = train()
        _ = p.place(day(.sunday))
        #expect(p.place(day(.sunday)) == .ignored)
        #expect(p.placed.count == 1)
    }

    @Test func solvedIgnoresInput() {
        var p = train()
        for d in DayOfWeek.allCases { #expect(p.place(day(d)) == .correct) }
        #expect(p.isSolved)
        #expect(p.current == nil)
        #expect(p.place(day(.monday)) == .ignored)
    }

    @Test func corrections() {
        var rng = SeededGenerator(seed: 43)
        var p = SequencePuzzle.yesterdayTomorrow(today: .friday, using: &rng)
        let wrong = p.pool.first { $0 != day(.thursday) }!
        _ = p.place(wrong)
        #expect(p.correction() == "Yesterday was Thursday. Try again!")
        p.resume()
        _ = p.place(day(.thursday))
        #expect(p.correction() == "Today is Friday. Try again!")

        var t = train()
        #expect(t.correction() == "Sunday comes first. Try again!")
        _ = t.place(day(.sunday))
        #expect(t.correction() == "Monday comes next. Try again!")
    }

    @Test func solvedSummary() {
        var rng = SeededGenerator(seed: 44)
        #expect(SequencePuzzle.yesterdayTomorrow(today: .friday, using: &rng).summary
                == "Yesterday was Thursday, today is Friday, and tomorrow will be Saturday!")
        #expect(train().summary == "Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday!")
    }
}
