//
//  SequencePuzzle.swift
//  DayByDay
//

/// Cards placed one at a time into ordered slots. Tapping or dragging a card
/// places it in the next slot; a wrong card waits for `resume()`.
nonisolated struct SequencePuzzle {
    struct Step {
        let answer: QuizItem
        let prompt: String
        /// Said after a wrong card, before "Try again!".
        let correction: String
    }

    let steps: [Step]
    /// The cards on offer, shuffled once.
    let pool: [QuizItem]
    /// Labels above the slots; nil for the train.
    let slotLabels: [String]?
    /// Said once every slot is filled.
    let summary: String
    private(set) var placed: [QuizItem] = []
    private(set) var isShowingCorrection = false

    var current: Step? { placed.count < steps.count ? steps[placed.count] : nil }
    var isSolved: Bool { current == nil }

    mutating func place(_ item: QuizItem) -> AnswerOutcome {
        guard let current, !isShowingCorrection, !placed.contains(item) else { return .ignored }
        guard item == current.answer else {
            isShowingCorrection = true
            return .incorrect(correctName: current.answer.name)
        }
        placed.append(item)
        return .correct
    }

    mutating func resume() {
        isShowingCorrection = false
    }

    func correction() -> String {
        guard let current else { return "" }
        return "\(current.correction) Try again!"
    }

    /// Sunday to Saturday, from all seven cards.
    static func weekTrain(using rng: inout some RandomNumberGenerator) -> SequencePuzzle {
        let days = DayOfWeek.allCases.map { Category.days.item($0) }
        let steps = days.indices.map { i in
            i == 0
                ? Step(answer: days[0], prompt: "Which day comes first?", correction: "\(days[0].name) comes first.")
                : Step(answer: days[i], prompt: "What comes after \(days[i - 1].name)?",
                       correction: "\(days[i].name) comes next.")
        }
        return SequencePuzzle(steps: steps, pool: days.shuffled(using: &rng), slotLabels: nil,
                              summary: days.map(\.name).joined(separator: ", ") + "!")
    }

    /// Yesterday, today and tomorrow, from those three cards plus one other day.
    static func yesterdayTomorrow(today: DayOfWeek, using rng: inout some RandomNumberGenerator) -> SequencePuzzle {
        func day(_ offset: Int) -> QuizItem {
            Category.days.item(DayOfWeek(rawValue: (today.rawValue + offset + 7) % 7)!)
        }
        let (yesterday, now, tomorrow) = (day(-1), day(0), day(1))
        let extra = (2...5).map(day).randomElement(using: &rng)!
        let steps = [
            Step(answer: yesterday, prompt: "Which day was yesterday?", correction: "Yesterday was \(yesterday.name)."),
            Step(answer: now, prompt: "Which day is today?", correction: "Today is \(now.name)."),
            Step(answer: tomorrow, prompt: "Which day will it be tomorrow?", correction: "Tomorrow will be \(tomorrow.name)."),
        ]
        return SequencePuzzle(
            steps: steps, pool: [yesterday, now, tomorrow, extra].shuffled(using: &rng),
            slotLabels: ["Yesterday", "Today", "Tomorrow"],
            summary: "Yesterday was \(yesterday.name), today is \(now.name), and tomorrow will be \(tomorrow.name)!")
    }
}
