import Testing
@testable import DayByDay

struct OrderSourcesTests {
    typealias Topic = DayByDay.Category

    func asked(_ q: Question) -> String {
        let after = q.prompt.components(separatedBy: "after ").last!
        return String(after.dropLast())
    }

    @Test func monthSeasons() {
        #expect([MonthOfYear.december, .january, .february].allSatisfy { $0.season == .winter })
        #expect(MonthOfYear.march.season == .spring)
        #expect(MonthOfYear.june.season == .summer)
        #expect([MonthOfYear.september, .november].allSatisfy { $0.season == .fall })
    }

    @Test func comesNextWraps() {
        var rng = SeededGenerator(seed: 31)
        let days = ComesNext(items: Topic.days.quizItems, noun: "day")
        let months = ComesNext(items: Topic.months.quizItems, noun: "month")
        var sawSaturday = false, sawDecember = false
        for i in 0..<300 {
            let d = days.next(correctCount: i % 5, excluding: nil, using: &rng)
            if asked(d) == "Saturday" { sawSaturday = true; #expect(d.answer.name == "Sunday") }
            let m = months.next(correctCount: i % 5, excluding: nil, using: &rng)
            if asked(m) == "December" { sawDecember = true; #expect(m.answer.name == "January") }
        }
        #expect(sawSaturday && sawDecember)
    }

    @Test func comesNextPrompt() {
        var rng = SeededGenerator(seed: 32)
        let q = ComesNext(items: Topic.days.quizItems, noun: "day").next(correctCount: 0, excluding: nil, using: &rng)
        #expect(q.prompt == "What day comes after \(asked(q))?")
    }

    @Test func comesNextNeverOffersAskedItem() {
        var rng = SeededGenerator(seed: 33)
        let source = ComesNext(items: Topic.days.quizItems, noun: "day")
        var previous: QuizItem?
        for i in 0..<300 {
            let q = source.next(correctCount: i % 5, excluding: previous, using: &rng)
            #expect(!q.choices.map(\.name).contains(asked(q)))
            #expect(q.answer != previous)
            previous = q.answer
        }
    }

    @Test func comesNextCorrection() {
        var rng = SeededGenerator(seed: 34)
        let q = ComesNext(items: Topic.days.quizItems, noun: "day").next(correctCount: 0, excluding: nil, using: &rng)
        let wrong = q.choices.first { $0 != q.answer }!
        #expect(q.correction(for: wrong) == "\(q.answer.name) comes after \(asked(q)). Try again!")
    }

    @Test func whichSeasonPromptMatchesAnswer() {
        var rng = SeededGenerator(seed: 35)
        for i in 0..<300 {
            let q = WhichSeason().next(correctCount: i % 5, excluding: nil, using: &rng)
            let monthName = q.prompt.replacingOccurrences(of: "Which season is ", with: "")
                .replacingOccurrences(of: " in?", with: "")
            let month = MonthOfYear.allCases.first { $0.name == monthName }!
            #expect(Topic.seasons.item(month.season) == q.answer)
            let wrong = q.choices.first { $0 != q.answer }!
            #expect(q.correction(for: wrong) == "\(monthName) is in \(q.answer.name). Try again!")
        }
    }

    @Test func mostAnswerIsLargest() {
        var rng = SeededGenerator(seed: 36)
        var previous: QuizItem?
        for i in 0..<300 {
            let q = Most().next(correctCount: i % 5, excluding: previous, using: &rng)
            let answer = q.answer.value(LearnNumber.self)!.numeral
            #expect(q.choices.filter { $0 != q.answer }.allSatisfy { $0.value(LearnNumber.self)!.numeral < answer })
            #expect(Set(q.choices).count == q.choices.count)
            #expect(q.answer != previous)
            previous = q.answer
        }
    }

    @Test func mostFacts() {
        var rng = SeededGenerator(seed: 37)
        let q = Most().next(correctCount: 0, excluding: nil, using: &rng)
        let wrong = q.choices.first { $0 != q.answer }!
        #expect(q.correction(for: wrong) == "That one has \(wrong.value(LearnNumber.self)!.numeral). Try again!")
    }
}
