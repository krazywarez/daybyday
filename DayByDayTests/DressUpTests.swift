import Testing
import UIKit
@testable import DayByDay

struct DressUpTests {
    @Test func onlyOneSuitableChoice() {
        var rng = SeededGenerator(seed: 81)
        var previous: QuizItem?
        var weathers = Set<LearnWeather>()
        for i in 0..<300 {
            let q = DressUp().next(correctCount: i % 5, excluding: previous, using: &rng)
            let weather = q.shown[0].value(LearnWeather.self)!
            weathers.insert(weather)
            let suitable = q.choices.filter { Clothing.from($0)!.suits.contains(weather) }
            #expect(suitable == [q.answer])
            #expect((3...4).contains(q.choices.count))
            #expect(q.answer != previous)
            previous = q.answer
        }
        #expect(weathers == [.sunny, .rainy, .snowy, .windy])
    }

    @Test func promptShownAndFacts() {
        var rng = SeededGenerator(seed: 82)
        let q = DressUp().next(correctCount: 0, excluding: nil, using: &rng)
        let weather = q.shown[0].value(LearnWeather.self)!
        #expect(q.prompt == "It's \(weather.name.lowercased())! What should we wear?")
        let wrong = q.choices.first { $0 != q.answer }!
        #expect(q.correction(for: wrong) == "\(Clothing.from(wrong)!.fact) Try again!")
        #expect(Clothing.umbrella.fact == "An umbrella is for rainy days.")
        // Coat and jacket look alike, so neither is ever the wrong one beside the other.
        #expect(Clothing.coat.suits == Clothing.jacket.suits)
        // A coat is fine in the rain too, so it is never a wrong answer there.
        #expect(Clothing.coat.suits.contains(.rainy))
    }

    @Test(arguments: Clothing.allCases) func symbolExists(_ c: Clothing) {
        #expect(UIImage(systemName: c.symbol) != nil, "\(c.symbol)")
    }

    @Test func idsPinned() {
        #expect(Clothing.allCases.map(\.item.id) == [
            "clothing.sunglasses", "clothing.sunHat", "clothing.tshirt", "clothing.umbrella",
            "clothing.coat", "clothing.jacket",
        ])
        #expect(Clothing.allCases.allSatisfy { Clothing.from($0.item) == $0 })
    }
}
