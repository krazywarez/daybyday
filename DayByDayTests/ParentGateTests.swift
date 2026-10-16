import Testing
@testable import DayByDay

struct ParentGateTests {
    @Test func operandsInRange() {
        var rng = SeededGenerator(seed: 9)
        for _ in 0..<1000 {
            let c = ParentGateChallenge.random(using: &rng)
            #expect((6...9).contains(c.a))
            #expect((6...9).contains(c.b))
        }
    }

    @Test func acceptsCorrectSum() {
        let c = ParentGateChallenge(a: 7, b: 8)
        #expect(c.answer == 15)
        #expect(c.accepts("15"))
        #expect(c.accepts(" 15 "))
    }

    @Test func rejectsWrong() {
        let c = ParentGateChallenge(a: 7, b: 8)
        #expect(!c.accepts("14"))
        #expect(!c.accepts(""))
        #expect(!c.accepts("abc"))
    }
}
