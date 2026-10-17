import Foundation
import Testing
@testable import DayByDay

struct ItemProgressTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    /// `(id, correct, seconds after start)`.
    func progress(_ answers: [(String, Bool, TimeInterval)]) -> ItemProgress {
        ItemProgress(answers.map { AnswerFact(itemID: $0.0, isCorrect: $0.1, timestamp: start + $0.2) })
    }

    @Test func untouchedIsNew() {
        #expect(progress([]).status("monday") == .new)
    }

    @Test func oneRightIsNew() {
        #expect(progress([("monday", true, 0)]).status("monday") == .new)
    }

    @Test func twoRightIsKnown() {
        #expect(progress([("monday", true, 0), ("monday", true, 300)]).status("monday") == .known)
    }

    @Test func missIsLearning() {
        #expect(progress([("june", false, 0)]).status("june") == .learning)
    }

    @Test func threeRightClearsMiss() {
        let p = progress([("june", false, 0), ("june", true, 300), ("june", true, 600), ("june", true, 900)])
        #expect(p.status("june") == .known)
        let two = progress([("june", false, 0), ("june", true, 300), ("june", true, 600)])
        #expect(two.status("june") == .learning)
    }

    @Test func retryDoesNotCount() {
        var answers: [(String, Bool, TimeInterval)] = [("june", false, 0), ("june", true, 5), ("june", true, 300), ("june", true, 600)]
        #expect(progress(answers).status("june") == .learning)
        answers.append(("june", true, 900))
        #expect(progress(answers).status("june") == .known)
    }

    @Test func newMissReopens() {
        let answers = (0..<5).map { ("july", true, TimeInterval($0) * 300) } + [("july", false, 2000)]
        #expect(progress(answers).status("july") == .learning)
    }

    @Test func weights() {
        let p = progress([("june", false, 0), ("july", true, 0), ("july", true, 300)])
        #expect(p.weight("june") == 3)
        #expect(p.weight("july") == 1)
        #expect(p.weight("august") == 1)
    }

    @Test func lastMissIsMostRecent() {
        let p = progress([("june", false, 0), ("june", true, 300), ("june", false, 600)])
        #expect(p.lastMiss["june"] == start + 600)
    }

    @Test func unorderedInput() {
        let p = progress([("june", true, 900), ("june", true, 300), ("june", false, 0), ("june", true, 600)])
        #expect(p.status("june") == .known)
    }
}
