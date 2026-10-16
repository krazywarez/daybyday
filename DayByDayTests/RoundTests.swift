import Testing
@testable import DayByDay

struct RoundTests {
    let days = Category.days.quizItems
    let picker = QuestionPicker(choiceCount: 4) { "Can you find \($0.name)?" }

    @Test func choicesIncludeAnswerAndAreDistinct() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<50 {
            let q = picker.next(from: days, excluding: nil, using: &rng)
            #expect(q.choices.count == 4)
            #expect(q.choices.contains(q.answer))
            #expect(Set(q.choices).count == 4)
        }
    }

    @Test func choiceCountClampsToItemCount() {
        var rng = SeededGenerator(seed: 2)
        let wide = QuestionPicker(choiceCount: 6) { $0.name }
        let q = wide.next(from: Category.seasons.quizItems, excluding: nil, using: &rng)
        #expect(q.choices.count == 4)
    }

    @Test func neverRepeatsPreviousAnswer() {
        var rng = SeededGenerator(seed: 3)
        let previous = days[0]
        for _ in 0..<200 {
            #expect(picker.next(from: days, excluding: previous, using: &rng).answer != previous)
        }
    }

    @Test func promptUsesClosure() {
        var rng = SeededGenerator(seed: 4)
        let q = picker.next(from: days, excluding: nil, using: &rng)
        #expect(q.prompt == "Can you find \(q.answer.name)?")
    }

    @Test func wrongAnswerRetriesSameQuestion() {
        var round = Round(items: days, picker: picker, rng: SeededGenerator(seed: 5))
        let question = round.current
        let wrong = question.choices.first { $0 != question.answer }!
        #expect(round.answer(wrong) == .incorrect(correctName: question.answer.name))
        #expect(round.current == question)
        #expect(round.correctCount == 0)
        #expect(!round.isAwaitingNext)
    }

    @Test func tapsWhileAwaitingNextAreIgnored() {
        var round = Round(items: days, picker: picker, rng: SeededGenerator(seed: 6))
        let answer = round.current.answer
        #expect(round.answer(answer) == .correct)
        #expect(round.isAwaitingNext)
        #expect(round.answer(answer) == .ignored)
        #expect(round.answer(round.current.choices.first { $0 != answer }!) == .ignored)
        #expect(round.correctCount == 1)
    }

    @Test func finishesAfterFiveCorrect() {
        var round = Round(items: days, picker: picker, rng: SeededGenerator(seed: 7))
        for _ in 0..<Round.length {
            #expect(!round.isFinished)
            _ = round.answer(round.current.answer)
            round.advance()
        }
        #expect(round.isFinished)
        #expect(round.correctCount == 5)
    }

    @Test func tapsDuringCorrectionAreIgnored() {
        var round = Round(items: days, picker: picker, rng: SeededGenerator(seed: 8))
        let question = round.current
        let wrong = question.choices.filter { $0 != question.answer }
        #expect(round.answer(wrong[0]) == .incorrect(correctName: question.answer.name))
        #expect(round.answer(wrong[1]) == .ignored)
        #expect(round.answer(question.answer) == .ignored)
        round.resume()
        #expect(round.answer(question.answer) == .correct)
    }

    @Test func finalAnswerCelebratesBeforeCompleting() {
        var round = Round(items: days, picker: picker, rng: SeededGenerator(seed: 9))
        for _ in 0..<(Round.length - 1) {
            _ = round.answer(round.current.answer)
            round.advance()
        }
        _ = round.answer(round.current.answer)
        #expect(round.isFinished)
        #expect(!round.isComplete)
        round.advance()
        #expect(round.isComplete)
    }
}
