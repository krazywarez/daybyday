import Foundation
import Testing
@testable import DayByDay

struct ProgressSummaryTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    /// Each known item gets two right answers; each missed item one miss.
    func summary(_ category: DayByDay.Category, known: [Int] = [], missed: [Int] = [], extra: [AnswerFact] = []) -> ProgressSummary {
        let items = category.quizItems
        var facts = extra
        for i in known {
            facts += [AnswerFact(itemID: items[i].id, isCorrect: true, timestamp: start),
                      AnswerFact(itemID: items[i].id, isCorrect: true, timestamp: start + 300)]
        }
        for i in missed {
            facts.append(AnswerFact(itemID: items[i].id, isCorrect: false, timestamp: start + Double(i)))
        }
        return ProgressSummary(category: category, progress: ItemProgress(facts))
    }

    @Test func notPlayed() {
        let s = summary(.food)
        #expect(s.known == "Not played yet.")
        #expect(s.missing == nil)
    }

    @Test func knowsAll() {
        let s = summary(.seasons, known: [0, 1, 2, 3])
        #expect(s.known == "Knows all 4 seasons.")
        #expect(s.missing == nil)
    }

    @Test func knowsSome() {
        #expect(summary(.days, known: [0, 1, 2, 3, 4]).known == "Knows 5 of 7 days.")
        #expect(summary(.weather, known: [0]).known?.hasSuffix("kinds of weather.") == true)
    }

    @Test func mixingUpList() {
        let s = summary(.months, known: [0], missed: [7, 5, 6])
        #expect(s.known == "Knows 1 of 12 months.")
        #expect(s.missing == "Still mixing up June, July and August.")
        #expect(summary(.months, missed: [5]).known == nil)
    }

    @Test func twoItemsUseAnd() {
        #expect(summary(.days, missed: [3, 4]).missing == "Still mixing up Wednesday and Thursday.")
        #expect(summary(.days, missed: [4]).missing == "Still mixing up Thursday.")
    }

    @Test func longListTruncates() {
        let s = summary(.alphabet, missed: [1, 3, 15, 16, 20, 21])
        #expect(s.missing == "Still mixing up B, D, P, Q and 2 more.")
    }

    @Test func unknownIDsIgnored() {
        let old = [AnswerFact(itemID: "lizard", isCorrect: false, timestamp: start)]
        #expect(summary(.animals, extra: old).known == "Not played yet.")
        #expect(summary(.animals, known: [0], extra: old).missing == nil)
    }

    @Test func justStarted() {
        let once = [AnswerFact(itemID: DayByDay.Category.days.quizItems[1].id, isCorrect: true, timestamp: start)]
        let s = summary(.days, extra: once)
        #expect(s.known == "Just started.")
        #expect(s.missing == nil)
    }
}
