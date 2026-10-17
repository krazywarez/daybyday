//
//  SortRound.swift
//  DayByDay
//

/// Six foods, one at a time, into a fruit bin or a vegetable bin.
nonisolated struct SortRound {
    let foods: [LearnFood]
    private(set) var fruitBin: [LearnFood] = []
    private(set) var vegetableBin: [LearnFood] = []
    private(set) var isShowingCorrection = false

    init(using rng: inout some RandomNumberGenerator) {
        let fruit = LearnFood.allCases.filter(\.isFruit).shuffled(using: &rng).prefix(3)
        let vegetables = LearnFood.allCases.filter { !$0.isFruit }.shuffled(using: &rng).prefix(3)
        foods = Array(fruit + vegetables).shuffled(using: &rng)
    }

    private var sorted: Int { fruitBin.count + vegetableBin.count }
    var current: LearnFood? { sorted < foods.count ? foods[sorted] : nil }
    var isDone: Bool { current == nil }

    var prompt: String? { current.map(Self.question) }

    mutating func place(isFruit: Bool) -> AnswerOutcome {
        guard let food = current, !isShowingCorrection else { return .ignored }
        guard isFruit == food.isFruit else {
            isShowingCorrection = true
            return .incorrect(correctName: food.name)
        }
        if isFruit { fruitBin.append(food) } else { vegetableBin.append(food) }
        return .correct
    }

    mutating func resume() {
        isShowingCorrection = false
    }

    func correction() -> String {
        current.map { "\(Self.fact(for: $0)) Try again!" } ?? ""
    }

    static func question(for food: LearnFood) -> String {
        let name = food.name.lowercased()
        switch food {
        case .grapes:          return "Are grapes a fruit or a vegetable?"
        case .corn, .broccoli: return "Is \(name) a fruit or a vegetable?"
        default:               return "Is the \(name) a fruit or a vegetable?"
        }
    }

    static func fact(for food: LearnFood) -> String {
        let name = food.name.lowercased()
        let kind = food.isFruit ? "fruit" : "vegetable"
        switch food {
        case .grapes:          return "Grapes are a \(kind)."
        case .corn, .broccoli: return "\(food.name) is a \(kind)."
        default:
            let article = "aeiou".contains(name.first!) ? "An" : "A"
            return "\(article) \(name) is a \(kind)."
        }
    }
}
