import Testing
@testable import DayByDay

struct PraisePhrasesTests {
    @Test func neverRepeatsConsecutively() {
        var rng = SeededGenerator(seed: 11)
        var phrases = PraisePhrases()
        var last = ""
        for _ in 0..<500 {
            let next = phrases.next(using: &rng)
            #expect(next != last)
            #expect(PraisePhrases.all.contains(next))
            last = next
        }
    }

    @Test func atLeastEightPhrases() {
        #expect(Set(PraisePhrases.all).count >= 8)
    }

    @Test func correctionCopy() {
        #expect(PraisePhrases.correction(for: "Thursday") == "That's Thursday! Try again.")
    }
}
