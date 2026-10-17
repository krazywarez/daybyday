import Testing
@testable import DayByDay

struct SortRoundTests {
    func round(_ seed: UInt64 = 91) -> SortRound {
        var rng = SeededGenerator(seed: seed)
        return SortRound(using: &rng)
    }

    @Test func threeOfEach() {
        for seed in 0..<50 {
            let r = round(UInt64(seed))
            #expect(r.foods.filter(\.isFruit).count == 3)
            #expect(r.foods.filter { !$0.isFruit }.count == 3)
            #expect(Set(r.foods).count == 6)
        }
    }

    @Test func correctBinAdvances() {
        var r = round()
        let first = r.current!
        #expect(r.place(isFruit: first.isFruit) == .correct)
        #expect((first.isFruit ? r.fruitBin : r.vegetableBin) == [first])
        #expect(r.current == r.foods[1])
    }

    @Test func wrongBinWaits() {
        var r = round()
        let first = r.current!
        #expect(r.place(isFruit: !first.isFruit) == .incorrect(correctName: first.name))
        #expect(r.place(isFruit: first.isFruit) == .ignored)
        r.resume()
        #expect(r.place(isFruit: first.isFruit) == .correct)
    }

    @Test func doneIgnoresInput() {
        var r = round()
        while let food = r.current { _ = r.place(isFruit: food.isFruit) }
        #expect(r.isDone)
        #expect(r.place(isFruit: true) == .ignored)
        #expect(r.fruitBin.count + r.vegetableBin.count == 6)
    }

    @Test func promptAndCorrection() {
        var r = round()
        let food = r.current!
        #expect(r.prompt == SortRound.question(for: food))
        _ = r.place(isFruit: !food.isFruit)
        #expect(r.correction().hasSuffix("is a \(food.isFruit ? "fruit" : "vegetable"). Try again!"))
        #expect(SortRound.fact(for: .apple) == "An apple is a fruit.")
        #expect(SortRound.fact(for: .carrot) == "A carrot is a vegetable.")
    }

    @Test func grammarForEveryFood() {
        #expect(SortRound.fact(for: .grapes) == "Grapes are a fruit.")
        #expect(SortRound.fact(for: .corn) == "Corn is a vegetable.")
        #expect(SortRound.fact(for: .broccoli) == "Broccoli is a vegetable.")
        #expect(SortRound.question(for: .grapes) == "Are grapes a fruit or a vegetable?")
        #expect(SortRound.question(for: .corn) == "Is corn a fruit or a vegetable?")
        #expect(SortRound.question(for: .apple) == "Is the apple a fruit or a vegetable?")
    }
}
