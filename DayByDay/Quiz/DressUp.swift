//
//  DressUp.swift
//  DayByDay
//

/// Things to wear, for "Dress for the weather".
nonisolated enum Clothing: Int, CaseIterable {
    case sunglasses, sunHat, tshirt, umbrella, coat, jacket

    var name: String {
        switch self {
        case .sunglasses: "Sunglasses"
        case .sunHat:     "Sun hat"
        case .tshirt:     "T-shirt"
        case .umbrella:   "Umbrella"
        case .coat:       "Coat"
        case .jacket:     "Jacket"
        }
    }

    var symbol: String {
        switch self {
        case .sunglasses: "sunglasses.fill"
        case .sunHat:     "hat.widebrim.fill"
        case .tshirt:     "tshirt.fill"
        case .umbrella:   "umbrella.fill"
        case .coat:       "coat.fill"
        case .jacket:     "jacket.fill"
        }
    }

    var suits: Set<LearnWeather> {
        switch self {
        case .sunglasses, .sunHat, .tshirt: [.sunny]
        case .umbrella: [.rainy]
        // Coat and jacket look alike, so they suit the same weather; both
        // are fine in the rain, so neither is a wrong answer there.
        case .coat, .jacket: [.rainy, .snowy, .windy]
        }
    }

    var fact: String {
        switch self {
        case .sunglasses: "Sunglasses are for sunny days."
        case .sunHat:     "A sun hat is for sunny days."
        case .tshirt:     "A T-shirt is for warm days."
        case .umbrella:   "An umbrella is for rainy days."
        case .coat:       "A coat is for cold days."
        case .jacket:     "A jacket is for cold, windy days."
        }
    }

    /// Recorded under the weather topic with a "clothing." id.
    var item: QuizItem {
        QuizItem(id: "clothing.\(self)", name: name, category: .weather)
    }

    static func from(_ item: QuizItem) -> Clothing? {
        allCases.first { $0.item.id == item.id }
    }
}

/// "It's rainy! What should we wear?" Exactly one choice suits the weather.
nonisolated struct DressUp: QuestionSource {
    static let weathers: [LearnWeather] = [.sunny, .rainy, .snowy, .windy]

    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let previousClothing = previous.flatMap(Clothing.from)
        func fresh(_ w: LearnWeather) -> [Clothing] {
            Clothing.allCases.filter { $0.suits.contains(w) && $0 != previousClothing }
        }
        let weather = Self.weathers.filter { !fresh($0).isEmpty }.randomElement(using: &rng)!
        let answer = fresh(weather).randomElement(using: &rng)!
        let count = Round.choiceCount(correctCount: correctCount)
        let others = Clothing.allCases.filter { !$0.suits.contains(weather) }
            .shuffled(using: &rng).prefix(count - 1)
        var facts: [QuizItem: String] = [:]
        for c in others { facts[c.item] = c.fact }
        return Question(prompt: "It's \(weather.name.lowercased())! What should we wear?",
                        choices: ([answer] + others).map(\.item).shuffled(using: &rng),
                        answer: answer.item, facts: facts,
                        shown: [Category.weather.item(weather)])
    }
}
