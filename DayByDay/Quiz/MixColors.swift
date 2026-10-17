//
//  MixColors.swift
//  DayByDay
//

/// "What do red and yellow make?" The two paints are shown above the choices.
nonisolated struct MixColors: QuestionSource {
    static let mixes: [(LearnColor, LearnColor, LearnColor)] = [
        (.red, .yellow, .orange), (.blue, .yellow, .green), (.red, .blue, .purple), (.red, .white, .pink),
    ]

    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let colors = Category.colors
        let (a, b, result) = Self.mixes.filter { colors.item($0.2) != previous }.randomElement(using: &rng)!
        let answer = colors.item(result)
        let ingredients = [colors.item(a), colors.item(b)].shuffled(using: &rng)
        let count = Round.choiceCount(correctCount: correctCount)
        let others = colors.quizItems.filter { $0 != answer && !ingredients.contains($0) }
            .shuffled(using: &rng).prefix(count - 1)
        let (first, second) = (ingredients[0].name, ingredients[1].name.lowercased())
        var facts: [QuizItem: String] = [:]
        for item in others { facts[item] = "\(first) and \(second) make \(answer.name.lowercased())." }
        return Question(prompt: "What do \(first.lowercased()) and \(second) make?",
                        choices: ([answer] + others).shuffled(using: &rng),
                        answer: answer, facts: facts, shown: ingredients)
    }
}
