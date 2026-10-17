import Testing
@testable import DayByDay

struct MixColorsTests {
    typealias Topic = DayByDay.Category

    func color(_ item: QuizItem) -> LearnColor { item.value(LearnColor.self)! }

    @Test func everyMixIsRight() {
        let table: [Set<LearnColor>: LearnColor] = [
            [.red, .yellow]: .orange, [.blue, .yellow]: .green, [.red, .blue]: .purple, [.red, .white]: .pink,
        ]
        var rng = SeededGenerator(seed: 61)
        var seen = Set<LearnColor>()
        for i in 0..<300 {
            let q = MixColors().next(correctCount: i % 5, excluding: nil, using: &rng)
            #expect(q.shown.count == 2)
            #expect(table[Set(q.shown.map(color))] == color(q.answer))
            seen.insert(color(q.answer))
        }
        #expect(seen == [.orange, .green, .purple, .pink])
    }

    @Test func mixNeverOffersIngredients() {
        var rng = SeededGenerator(seed: 62)
        var previous: QuizItem?
        for i in 0..<300 {
            let q = MixColors().next(correctCount: i % 5, excluding: previous, using: &rng)
            #expect(Set(q.choices).isDisjoint(with: q.shown))
            #expect(q.choices.contains(q.answer))
            #expect(q.answer != previous)
            previous = q.answer
        }
    }

    @Test func mixPromptAndCorrection() {
        var rng = SeededGenerator(seed: 63)
        let q = MixColors().next(correctCount: 0, excluding: nil, using: &rng)
        let (a, b) = (q.shown[0].name, q.shown[1].name)
        #expect(q.prompt == "What do \(a.lowercased()) and \(b.lowercased()) make?")
        let wrong = q.choices.first { $0 != q.answer }!
        #expect(q.correction(for: wrong) == "\(a) and \(b.lowercased()) make \(q.answer.name.lowercased()). Try again!")
    }
}
