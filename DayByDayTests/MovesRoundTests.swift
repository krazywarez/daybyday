import Testing
@testable import DayByDay

struct MovesRoundTests {
    @Test func fiveDistinctParts() {
        for seed in 0..<50 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let r = MovesRound(using: &rng)
            #expect(r.parts.count == MovesRound.length)
            #expect(Set(r.parts).count == MovesRound.length)
        }
    }

    @Test func commandsForAll() {
        #expect(LearnBodyPart.nose.command == "Touch your nose!")
        #expect(LearnBodyPart.hands.command == "Clap your hands!")
        #expect(LearnBodyPart.allCases.allSatisfy { $0.command.hasSuffix("!") })
        #expect(Set(LearnBodyPart.allCases.map(\.command)).count == LearnBodyPart.allCases.count)
    }

    @Test func advancesToEnd() {
        var rng = SeededGenerator(seed: 101)
        var r = MovesRound(using: &rng)
        for i in 0..<MovesRound.length {
            #expect(r.current == r.parts[i])
            r.next()
        }
        #expect(r.current == nil)
        #expect(r.isDone)
        r.next()
        #expect(r.isDone)
    }
}
