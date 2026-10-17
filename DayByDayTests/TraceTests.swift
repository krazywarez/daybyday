import CoreGraphics
import Testing
@testable import DayByDay

struct TraceTests {
    typealias Topic = DayByDay.Category

    static let cases: [(QuizItem, CGFloat)] = [
        Topic.shapes.item(LearnShape.circle), Topic.shapes.item(LearnShape.star),
        Topic.alphabet.item(LearnLetter.a), Topic.alphabet.item(LearnLetter.s),
    ].flatMap { item in [(item, CGFloat(300)), (item, CGFloat(600))] }

    func checker(_ item: QuizItem, _ size: CGFloat) -> TraceChecker {
        TraceChecker(region: TraceGuide.region(for: item, size: size), size: size)
    }

    @Test(arguments: cases) func tracingTheGuidePasses(_ item: QuizItem, _ size: CGFloat) {
        let c = checker(item, size)
        var rng = SeededGenerator(seed: 71)
        let wobble = size * 0.03
        let drawn = c.samples.map {
            CGPoint(x: $0.x + .random(in: -wobble...wobble, using: &rng),
                    y: $0.y + .random(in: -wobble...wobble, using: &rng))
        }
        #expect(c.passes(drawn), "\(item.name) \(size)")
    }

    @Test(arguments: cases) func scribbleElsewhereFails(_ item: QuizItem, _ size: CGFloat) {
        let c = checker(item, size)
        let region = TraceGuide.region(for: item, size: size)
        let away = (0..<400).map { i in
            CGPoint(x: CGFloat(i % 20) * size / 20, y: CGFloat(i / 20) * size / 20)
        }.filter { !region.contains($0) }
        #expect(!c.passes(away), "\(item.name) \(size)")
        #expect(c.score(away).accuracy < 0.5)
    }

    @Test(arguments: cases) func halfTraceFails(_ item: QuizItem, _ size: CGFloat) {
        let c = checker(item, size)
        let half = c.samples.sorted { $0.x < $1.x }.prefix(c.samples.count / 2)
        #expect(!c.passes(Array(half)), "\(item.name) \(size)")
    }

    @Test(arguments: cases) func regionsFitTheCanvas(_ item: QuizItem, _ size: CGFloat) {
        let box = TraceGuide.region(for: item, size: size).boundingBox
        #expect(CGRect(x: 0, y: 0, width: size, height: size).contains(box))
        #expect(box.width >= size * 0.4 || box.height >= size * 0.4)
        #expect(checker(item, size).samples.count > 40)
    }

    @Test func everyItemHasARegion() {
        for item in Topic.shapes.quizItems + Topic.alphabet.quizItems {
            #expect(!TraceGuide.region(for: item, size: 300).isEmpty, "\(item.name)")
        }
    }
}
