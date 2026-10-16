//
//  OrderSources.swift
//  DayByDay
//

nonisolated extension MonthOfYear {
    /// Same months as `Season.current`.
    var season: Season {
        switch self {
        case .march, .april, .may:          .spring
        case .june, .july, .august:         .summer
        case .september, .october, .november: .fall
        case .december, .january, .february:  .winter
        }
    }
}

/// "What day comes after Monday?" The answer is the next item, wrapping
/// from the last to the first. The asked item is never a choice.
nonisolated struct ComesNext: QuestionSource {
    let items: [QuizItem]
    let noun: String

    init(items: [QuizItem], noun: String) {
        precondition(items.count >= 3)
        self.items = items
        self.noun = noun
    }

    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let starts = items.indices.filter { items[($0 + 1) % items.count] != previous }
        let i = starts.randomElement(using: &rng)!
        let asked = items[i]
        let answer = items[(i + 1) % items.count]
        let count = min(Round.choiceCount(correctCount: correctCount), items.count - 1)
        let others = items.filter { $0 != asked && $0 != answer }.shuffled(using: &rng).prefix(count - 1)
        var facts: [QuizItem: String] = [:]
        for item in others { facts[item] = "\(answer.name) comes after \(asked.name)." }
        return Question(prompt: "What \(noun) comes after \(asked.name)?",
                        choices: ([answer] + others).shuffled(using: &rng),
                        answer: answer, facts: facts)
    }
}

/// "Which season is July in?"
nonisolated struct WhichSeason: QuestionSource {
    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let seasons = Category.seasons.quizItems
        let answer = seasons.filter { $0 != previous }.randomElement(using: &rng)!
        let season = answer.value(Season.self)!
        let month = MonthOfYear.allCases.filter { $0.season == season }.randomElement(using: &rng)!
        let count = Round.choiceCount(correctCount: correctCount)
        let others = seasons.filter { $0 != answer }.shuffled(using: &rng).prefix(count - 1)
        var facts: [QuizItem: String] = [:]
        for item in others { facts[item] = "\(month.name) is in \(answer.name)." }
        return Question(prompt: "Which season is \(month.name) in?",
                        choices: ([answer] + others).shuffled(using: &rng),
                        answer: answer, facts: facts)
    }
}

/// "Which one has the most?" Choices are piles of 1 to 10; the answer is the largest.
nonisolated struct Most: QuestionSource {
    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let numbers = Category.numbers.quizItems
        let count = Round.choiceCount(correctCount: correctCount)
        // The answer needs count - 1 smaller numbers below it.
        let answer = numbers.filter { $0.value(LearnNumber.self)!.numeral >= count && $0 != previous }
            .randomElement(using: &rng)!
        let top = answer.value(LearnNumber.self)!.numeral
        let others = numbers.filter { $0.value(LearnNumber.self)!.numeral < top }
            .shuffled(using: &rng).prefix(count - 1)
        var facts: [QuizItem: String] = [:]
        for item in others { facts[item] = "That one has \(item.value(LearnNumber.self)!.numeral)." }
        return Question(prompt: "Which one has the most?",
                        choices: ([answer] + others).shuffled(using: &rng),
                        answer: answer, facts: facts)
    }
}
