import Testing
@testable import DayByDay

struct CardLineTests {
    @Test func animalLines() {
        #expect(LearnAnimal.cow.cardLine == "Cow! Cows say moo.")
        #expect(LearnAnimal.fish.cardLine == "Fish! Fish swim in water.")
        #expect(LearnAnimal.allCases.allSatisfy { $0.cardLine.hasPrefix("\($0.name)! ") && $0.fact.hasSuffix(".") })
    }

    @Test func letterLines() {
        #expect(LearnLetter.b.cardLine == "b. b is for ball.")
        #expect(LearnLetter.allCases.allSatisfy { $0.cardLine.contains($0.exampleWord) })
    }

    @Test func lineQueueKeepsOnlyLatest() {
        var q = LineQueue()
        let first = q.next()
        let second = q.next()
        #expect(!q.isCurrent(first))
        #expect(q.isCurrent(second))
        q.cancel()
        #expect(!q.isCurrent(second))
    }

    /// A card's line waits for whichever sound is still playing, its own or an earlier card's.
    @Test func lineWaitsForEarlierSound() {
        #expect(abs(CardVoice.delay(newSound: 0, earlierSound: 1.1) - 1.3) < 1e-9)
        #expect(abs(CardVoice.delay(newSound: 0.9, earlierSound: 0.4) - 1.1) < 1e-9)
        #expect(CardVoice.delay(newSound: 0, earlierSound: 0) == 0)
    }
}
