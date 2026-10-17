//
//  Question.swift
//  DayByDay
//

nonisolated struct Question: Equatable {
    let prompt: String
    let choices: [QuizItem]
    let answer: QuizItem
    /// Played before the prompt is spoken.
    var sound: SoundEffect? = nil
    /// What to say about a choice when it is tapped by mistake.
    var facts: [QuizItem: String] = [:]
    /// Items drawn above the choices, e.g. the two paints being mixed.
    var shown: [QuizItem] = []

    func correction(for tapped: QuizItem) -> String {
        if let fact = facts[tapped] { return "\(fact) Try again!" }
        return PraisePhrases.correction(for: answer.name)
    }
}

nonisolated protocol QuestionSource {
    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question
}

/// "Find the one I name" questions. The answer comes from `answers`, the
/// other choices from `distractors`.
nonisolated struct QuestionPicker: QuestionSource {
    let answers: [QuizItem]
    let distractors: [QuizItem]
    let prompt: (QuizItem) -> String
    let sound: (QuizItem) -> SoundEffect?

    init(answers: [QuizItem], distractors: [QuizItem]? = nil,
         prompt: @escaping (QuizItem) -> String,
         sound: @escaping (QuizItem) -> SoundEffect? = { _ in nil }) {
        precondition(!answers.isEmpty)
        self.answers = answers
        self.distractors = distractors ?? answers
        self.prompt = prompt
        self.sound = sound
    }

    /// A random answer (never `previous` when there is an alternative) plus
    /// distinct distractors, shuffled.
    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let candidates = answers.count > 1 ? answers.filter { $0 != previous } : answers
        let answer = candidates.randomElement(using: &rng)!
        let others = distractors.filter { $0 != answer }.shuffled(using: &rng)
        let count = min(Round.choiceCount(correctCount: correctCount), others.count + 1)
        let choices = ([answer] + others.prefix(count - 1)).shuffled(using: &rng)
        return Question(prompt: prompt(answer), choices: choices, answer: answer, sound: sound(answer))
    }
}

/// Odd one out: all choices but one come from the same group, and the
/// prompt names the odd group's rule ("Which one can fly?").
nonisolated struct OddOneOut: QuestionSource {
    struct Group {
        let members: [QuizItem]
        /// Asked when the answer comes from this group.
        let question: String
        let fact: (QuizItem) -> String
    }

    let groups: (Group, Group)

    init(_ a: Group, _ b: Group) {
        groups = (a, b)
    }

    func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question {
        let pairs = [(groups.0, groups.1), (groups.1, groups.0)]
        var count = Round.choiceCount(correctCount: correctCount)
        var fitting = pairs.filter { $0.0.members.count >= count - 1 }
        if fitting.isEmpty {
            count = 3
            fitting = pairs.filter { $0.0.members.count >= count - 1 }
        }
        let (majority, odd) = fitting.randomElement(using: &rng)!
        let candidates = odd.members.count > 1 ? odd.members.filter { $0 != previous } : odd.members
        let answer = candidates.randomElement(using: &rng)!
        let others = Array(majority.members.shuffled(using: &rng).prefix(count - 1))
        var facts = [answer: odd.fact(answer)]
        for item in others { facts[item] = majority.fact(item) }
        return Question(prompt: odd.question,
                        choices: (others + [answer]).shuffled(using: &rng),
                        answer: answer, facts: facts)
    }
}
