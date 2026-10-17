import Testing
@testable import DayByDay

struct RoundTests {
    let days = Category.days.quizItems
    var picker: QuestionPicker { QuestionPicker(answers: days) { "Can you find \($0.name)?" } }

    @Test func choicesIncludeAnswerAndAreDistinct() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<50 {
            let q = picker.next(correctCount: 4, excluding: nil, using: &rng)
            #expect(q.choices.count == 4)
            #expect(q.choices.contains(q.answer))
            #expect(Set(q.choices).count == 4)
        }
    }

    @Test func choiceCountClampsToItemCount() {
        var rng = SeededGenerator(seed: 2)
        let small = QuestionPicker(answers: Array(Category.seasons.quizItems.prefix(2))) { $0.name }
        let q = small.next(correctCount: 4, excluding: nil, using: &rng)
        #expect(q.choices.count == 2)
    }

    @Test func neverRepeatsPreviousAnswer() {
        var rng = SeededGenerator(seed: 3)
        let previous = days[0]
        for _ in 0..<200 {
            #expect(picker.next(correctCount: 0, excluding: previous, using: &rng).answer != previous)
        }
    }

    @Test func promptUsesClosure() {
        var rng = SeededGenerator(seed: 4)
        let q = picker.next(correctCount: 0, excluding: nil, using: &rng)
        #expect(q.prompt == "Can you find \(q.answer.name)?")
    }

    @Test func wrongAnswerRetriesSameQuestion() {
        var round = Round(source: picker, rng: SeededGenerator(seed: 5))
        let question = round.current
        let wrong = question.choices.first { $0 != question.answer }!
        #expect(round.answer(wrong) == .incorrect(correctName: question.answer.name))
        #expect(round.current == question)
        #expect(round.correctCount == 0)
        #expect(!round.isAwaitingNext)
    }

    @Test func tapsWhileAwaitingNextAreIgnored() {
        var round = Round(source: picker, rng: SeededGenerator(seed: 6))
        let answer = round.current.answer
        #expect(round.answer(answer) == .correct)
        #expect(round.isAwaitingNext)
        #expect(round.answer(answer) == .ignored)
        #expect(round.answer(round.current.choices.first { $0 != answer }!) == .ignored)
        #expect(round.correctCount == 1)
    }

    @Test func finishesAfterFiveCorrect() {
        var round = Round(source: picker, rng: SeededGenerator(seed: 7))
        for _ in 0..<Round.length {
            #expect(!round.isFinished)
            _ = round.answer(round.current.answer)
            round.advance()
        }
        #expect(round.isFinished)
        #expect(round.correctCount == 5)
    }

    @Test func tapsDuringCorrectionAreIgnored() {
        var round = Round(source: picker, rng: SeededGenerator(seed: 8))
        let question = round.current
        let wrong = question.choices.filter { $0 != question.answer }
        #expect(round.answer(wrong[0]) == .incorrect(correctName: question.answer.name))
        #expect(round.answer(wrong[1]) == .ignored)
        #expect(round.answer(question.answer) == .ignored)
        round.resume()
        #expect(round.answer(question.answer) == .correct)
    }

    @Test func finalAnswerCelebratesBeforeCompleting() {
        var round = Round(source: picker, rng: SeededGenerator(seed: 9))
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

    @Test func choicesGrowWithinRound() {
        var round = Round(source: picker, rng: SeededGenerator(seed: 10))
        var counts: [Int] = []
        for _ in 0..<Round.length {
            counts.append(round.current.choices.count)
            _ = round.answer(round.current.answer)
            round.advance()
        }
        #expect(counts == [3, 3, 4, 4, 4])
    }

    @Test func distractorsComeFromTheirPool() {
        var rng = SeededGenerator(seed: 11)
        let source = QuestionPicker(answers: Array(days.prefix(3)), distractors: days) { $0.name }
        var distractorsSeen = Set<QuizItem>()
        for _ in 0..<300 {
            let q = source.next(correctCount: 4, excluding: nil, using: &rng)
            #expect(days.prefix(3).contains(q.answer))
            #expect(q.choices.allSatisfy(days.contains))
            #expect(Set(q.choices).count == 4)
            distractorsSeen.formUnion(q.choices.filter { $0 != q.answer })
        }
        #expect(distractorsSeen.contains { !days.prefix(3).contains($0) })
    }

    @Test func smallAnswerPoolStillVaries() {
        var rng = SeededGenerator(seed: 12)
        let source = QuestionPicker(answers: Array(days.prefix(2)), distractors: days) { $0.name }
        for _ in 0..<100 {
            #expect(source.next(correctCount: 0, excluding: days[0], using: &rng).answer == days[1])
        }
    }

    @Test func soundComesFromClosure() {
        var rng = SeededGenerator(seed: 13)
        let source = QuestionPicker(answers: days, prompt: { $0.name }, sound: { _ in .moo })
        #expect(source.next(correctCount: 0, excluding: nil, using: &rng).sound == .moo)
        #expect(picker.next(correctCount: 0, excluding: nil, using: &rng).sound == nil)
    }

    let food = Category.food
    var fruits: [QuizItem] { LearnFood.allCases.filter(\.isFruit).map(food.item) }
    var vegetables: [QuizItem] { LearnFood.allCases.filter { !$0.isFruit }.map(food.item) }
    var fruitOrVegetable: OddOneOut {
        OddOneOut(.init(members: fruits, question: "Which one is a fruit?") { "\($0.name) is a fruit." },
                  .init(members: vegetables, question: "Which one is a vegetable?") { "\($0.name) is a vegetable." })
    }

    @Test func correctionUsesFactWhenPresent() {
        let apple = food.item(LearnFood.apple), carrot = food.item(LearnFood.carrot)
        let q = Question(prompt: "", choices: [apple, carrot], answer: carrot, facts: [apple: "Apple is a fruit."])
        #expect(q.correction(for: apple) == "Apple is a fruit. Try again!")
        let plain = Question(prompt: "", choices: [apple, carrot], answer: carrot)
        #expect(plain.correction(for: apple) == "That's Carrot! Try again.")
    }

    @Test func oddOneOutShape() {
        var rng = SeededGenerator(seed: 14)
        for correctCount in [0, 4] {
            for _ in 0..<300 {
                let q = fruitOrVegetable.next(correctCount: correctCount, excluding: nil, using: &rng)
                let oddGroup = fruits.contains(q.answer) ? fruits : vegetables
                #expect(q.choices.filter(oddGroup.contains) == [q.answer])
                #expect(q.choices.count == Round.choiceCount(correctCount: correctCount))
                #expect(Set(q.choices).count == q.choices.count)
                #expect(q.facts.count == q.choices.count)
                #expect(q.prompt == (oddGroup == fruits ? "Which one is a fruit?" : "Which one is a vegetable?"))
            }
        }
    }

    @Test func oddOneOutNeverRepeatsPrevious() {
        var rng = SeededGenerator(seed: 15)
        let previous = vegetables[0]
        for _ in 0..<200 {
            #expect(fruitOrVegetable.next(correctCount: 0, excluding: previous, using: &rng).answer != previous)
        }
    }

    @Test func oddOneOutFallsBackToThree() {
        var rng = SeededGenerator(seed: 16)
        let source = OddOneOut(.init(members: Array(fruits.prefix(2)), question: "") { $0.name },
                               .init(members: Array(vegetables.prefix(2)), question: "") { $0.name })
        #expect(source.next(correctCount: 4, excluding: nil, using: &rng).choices.count == 3)
    }

    @Test func choiceCountGrows() {
        #expect((0...4).map(Round.choiceCount) == [3, 3, 4, 4, 4])
    }

    @Test func newRoundAvoidsPreviousAnswer() {
        for seed in 0..<200 {
            let round = Round(source: picker, after: days[3], rng: SeededGenerator(seed: UInt64(seed)))
            #expect(round.current.answer != days[3])
        }
    }

    @Test func weightedPickFavorsLearning() {
        var weighted = picker
        weighted.weights = [days[3]: 3]
        var rng = SeededGenerator(seed: 70)
        let hits = (0..<2000).filter { _ in weighted.next(correctCount: 0, excluding: nil, using: &rng).answer == days[3] }.count
        // 3 of 9 shares, against 1 of 7 unweighted.
        #expect((500...900).contains(hits))
    }

    @Test func allLearningStillVaries() {
        var weighted = picker
        weighted.weights = Dictionary(uniqueKeysWithValues: days.map { ($0, 3.0) })
        var rng = SeededGenerator(seed: 71)
        let answers = Set((0..<200).map { _ in weighted.next(correctCount: 0, excluding: nil, using: &rng).answer })
        #expect(answers.count == days.count)
    }

    @Test func weightsKeepPreviousRule() {
        var weighted = picker
        weighted.weights = [days[0]: 3]
        var rng = SeededGenerator(seed: 72)
        for _ in 0..<200 {
            #expect(weighted.next(correctCount: 0, excluding: days[0], using: &rng).answer != days[0])
        }
        var single = QuestionPicker(answers: [days[0]], distractors: days) { $0.name }
        single.weights = [days[0]: 3]
        #expect(single.next(correctCount: 0, excluding: days[0], using: &rng).answer == days[0])
    }

    @Test func emptyWeightsMatchOldPicks() {
        var a = SeededGenerator(seed: 73), b = SeededGenerator(seed: 73)
        var unweighted = picker
        unweighted.weights = [:]
        for _ in 0..<50 {
            #expect(picker.next(correctCount: 2, excluding: nil, using: &a) == unweighted.next(correctCount: 2, excluding: nil, using: &b))
        }
    }

    @Test func oddOneOutUsesWeights() {
        guard var source = Category.animals.questionSource(for: .oddOneOut) as? OddOneOut else {
            Issue.record("not odd one out"); return
        }
        let bird = Category.animals.item(LearnAnimal.bird)
        source.weights = [bird: 50]
        var rng = SeededGenerator(seed: 74)
        let hits = (0..<400).filter { _ in source.next(correctCount: 0, excluding: nil, using: &rng).answer == bird }.count
        #expect(hits > 120)
    }
}
