import Testing
@testable import DayByDay

struct CountingTests {
    func round(target: Int, seed: UInt64 = 51) -> CountingRound {
        var rng = SeededGenerator(seed: seed)
        return CountingRound(target: target, thing: CountingRound.things[0], using: &rng)
    }

    @Test func countsEachObjectOnce() {
        var r = round(target: 4)
        #expect(r.tap(0) == 1)
        #expect(r.tap(1) == 2)
        #expect(r.tap(1) == nil)
        #expect(r.tap(2) == 3)
        #expect(r.counted == [0, 1, 2])
    }

    @Test func ignoresOutOfRangeAndDone() {
        var r = round(target: 2)
        #expect(r.tap(2) == nil)
        #expect(r.tap(-1) == nil)
        _ = r.tap(0); _ = r.tap(1)
        #expect(r.isSetDone)
        #expect(r.tap(0) == nil)
    }

    @Test func setsNeverRepeatTarget() {
        var rng = SeededGenerator(seed: 52)
        var r = CountingRound(using: &rng)
        var previous = r.target
        for _ in 0..<200 {
            for i in 0..<r.target { _ = r.tap(i) }
            r.nextSet(using: &rng)
            if r.isComplete {
                r = CountingRound(using: &rng)
                previous = r.target
                continue
            }
            #expect((1...10).contains(r.target))
            #expect(r.target != previous)
            #expect(r.counted.isEmpty)
            previous = r.target
        }
    }

    @Test func completesAfterFiveSets() {
        var rng = SeededGenerator(seed: 53)
        var r = CountingRound(using: &rng)
        for set in 1...CountingRound.length {
            #expect(!r.isComplete)
            let ignored = r.nextSetIgnoredUntilDone(using: &rng)
            #expect(ignored)
            for i in 0..<r.target { _ = r.tap(i) }
            r.nextSet(using: &rng)
            #expect(r.setsDone == set)
        }
        #expect(r.isComplete)
    }

    @Test func summaryCopy() {
        let star = CountingRound.things[0]
        #expect(round(target: 1).summary() == "One! There is one \(star.singular).")
        #expect(round(target: 3).summary() == "Three! There are three \(star.plural).")
        #expect(star.singular == "star" && star.plural == "stars")
    }

    @Test func thingsDiffer() {
        #expect(CountingRound.things.map(\.singular) == ["star", "heart", "leaf", "moon", "fish"])
        #expect(CountingRound.things.map(\.plural) == ["stars", "hearts", "leaves", "moons", "fish"])
    }
}

extension CountingRound {
    /// nextSet() before the set is done must not advance.
    mutating func nextSetIgnoredUntilDone(using rng: inout some RandomNumberGenerator) -> Bool {
        let before = (target, setsDone)
        nextSet(using: &rng)
        return target == before.0 && setsDone == before.1
    }
}
