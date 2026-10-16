//
//  Question.swift
//  DayByDay
//

nonisolated struct Question: Equatable {
    let prompt: String
    let choices: [QuizItem]
    let answer: QuizItem
}

nonisolated struct QuestionPicker {
    var choiceCount: Int
    var prompt: (QuizItem) -> String

    /// Picks a random answer (never `previous` when there is an alternative)
    /// plus distinct distractors, shuffled.
    func next(from items: [QuizItem], excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let candidates = items.count > 1 ? items.filter { $0 != previous } : items
        let answer = candidates.randomElement(using: &rng)!
        let distractors = items.filter { $0 != answer }
            .shuffled(using: &rng)
            .prefix(min(choiceCount, items.count) - 1)
        let choices = ([answer] + distractors).shuffled(using: &rng)
        return Question(prompt: prompt(answer), choices: choices, answer: answer)
    }
}
