//
//  Round.swift
//  DayByDay
//

nonisolated enum AnswerOutcome: Equatable {
    case correct
    case incorrect(correctName: String)
    case ignored
}

/// A fixed-length run of questions. A wrong answer keeps the same question and
/// waits for `resume()`; a correct one waits for `advance()`. Answers are
/// ignored while either kind of feedback plays.
nonisolated struct Round {
    static let length = 5

    private let items: [QuizItem]
    private let picker: QuestionPicker
    private var rng: any RandomNumberGenerator
    private(set) var current: Question
    private(set) var correctCount = 0
    private(set) var isAwaitingNext = false
    private(set) var isShowingCorrection = false

    var isFinished: Bool { correctCount == Round.length }

    /// True once the last correct answer's feedback is done.
    var isComplete: Bool { isFinished && !isAwaitingNext }

    init(items: [QuizItem], picker: QuestionPicker, rng: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        var rng: any RandomNumberGenerator = rng
        self.items = items
        self.picker = picker
        self.current = picker.next(from: items, excluding: nil, using: &rng)
        self.rng = rng
    }

    mutating func answer(_ item: QuizItem) -> AnswerOutcome {
        guard !isAwaitingNext, !isShowingCorrection, !isFinished else { return .ignored }
        guard item == current.answer else {
            isShowingCorrection = true
            return .incorrect(correctName: current.answer.name)
        }
        correctCount += 1
        isAwaitingNext = true
        return .correct
    }

    mutating func resume() {
        isShowingCorrection = false
    }

    mutating func advance() {
        guard isAwaitingNext else { return }
        isAwaitingNext = false
        guard !isFinished else { return }
        current = picker.next(from: items, excluding: current.answer, using: &rng)
    }
}
