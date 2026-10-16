import Testing
import UIKit
@testable import DayByDay

struct GameTests {
    typealias Topic = DayByDay.Category

    @Test func catalog() {
        for c in Topic.gridCases {
            #expect(c.games.first == .findIt)
        }
        #expect(Topic.gridCases.filter { $0.games.contains(.oddOneOut) } == [.shapes, .animals, .food])
        #expect(Topic.gridCases.filter { $0.games.contains(.listen) } == [.numbers, .animals, .alphabet, .weather])
        #expect(Topic.days.games == [.findIt, .comesNext, .weekTrain, .yesterdayTomorrow])
        #expect(Topic.months.games == [.findIt, .comesNext, .yearWheel])
        #expect(Topic.seasons.games == [.findIt, .whichSeason])
        #expect(Topic.numbers.games == [.findIt, .listen, .counting, .most])
    }

    @Test(arguments: Topic.gridCases) func everyGameMakesValidQuestions(_ c: Topic) {
        var rng = SeededGenerator(seed: 21)
        for game in c.games where game.usesRound {
            let source = c.questionSource(for: game)
            var previous: QuizItem?
            for i in 0..<300 {
                let q = source.next(correctCount: i % 5, excluding: previous, using: &rng)
                #expect(q.choices.contains(q.answer), "\(c) \(game)")
                #expect(Set(q.choices).count == q.choices.count, "\(c) \(game)")
                #expect((3...4).contains(q.choices.count), "\(c) \(game)")
                #expect(q.answer != previous, "\(c) \(game)")
                #expect(q.choices.allSatisfy { $0.category == c })
                #expect(!q.prompt.isEmpty)
                previous = q.answer
            }
        }
    }

    static func group(_ item: QuizItem) -> Bool {
        if let a = item.value(LearnAnimal.self) { return a.canFly }
        if let f = item.value(LearnFood.self) { return f.isFruit }
        return item.value(LearnShape.self)!.hasCorners!
    }

    @Test(arguments: [Topic.shapes, .animals, .food]) func oddOneOutHasExactlyOneOddChoice(_ c: Topic) {
        var rng = SeededGenerator(seed: 22)
        let source = c.questionSource(for: .oddOneOut)
        for i in 0..<300 {
            let q = source.next(correctCount: i % 5, excluding: nil, using: &rng)
            let odd = Self.group(q.answer)
            #expect(q.choices.filter { Self.group($0) == odd } == [q.answer], "\(c)")
            #expect(q.facts.count == q.choices.count)
        }
    }

    @Test func oddOneOutLeavesOutHeart() {
        var rng = SeededGenerator(seed: 23)
        let heart = Topic.shapes.item(LearnShape.heart)
        for _ in 0..<300 {
            #expect(!Topic.shapes.questionSource(for: .oddOneOut)
                .next(correctCount: 4, excluding: nil, using: &rng).choices.contains(heart))
        }
    }

    @Test func oddOneOutFacts() {
        var rng = SeededGenerator(seed: 24)
        let q = Topic.food.questionSource(for: .oddOneOut).next(correctCount: 0, excluding: nil, using: &rng)
        for item in q.choices {
            let kind = item.value(LearnFood.self)!.isFruit ? "fruit" : "vegetable"
            #expect(q.facts[item] == "\(item.name) is a \(kind).")
        }
    }

    func questions(_ c: Topic, _ game: Game, count: Int = 300) -> [Question] {
        var rng = SeededGenerator(seed: 25)
        let source = c.questionSource(for: game)
        return (0..<count).map { source.next(correctCount: $0 % 5, excluding: nil, using: &rng) }
    }

    @Test func listenCues() {
        let animals = questions(.animals, .listen)
        #expect(animals.allSatisfy { $0.sound != nil && $0.prompt == "Who says this?" })
        #expect(Set(animals.map(\.answer)).count == 7)
        let cow = animals.first { $0.answer.value(LearnAnimal.self) == .cow }!
        #expect(cow.sound == .moo)

        let weather = questions(.weather, .listen)
        let sounds: [LearnWeather: SoundEffect] = [.rainy: .rain, .windy: .wind, .stormy: .thunder]
        #expect(weather.allSatisfy { sounds[$0.answer.value(LearnWeather.self)!] == $0.sound })
        #expect(weather.allSatisfy { $0.prompt == "What weather sounds like this?" })

        let numbers = questions(.numbers, .listen)
        #expect(numbers.allSatisfy { $0.sound == .beeps($0.answer.value(LearnNumber.self)!.numeral) })
        #expect(numbers.allSatisfy { $0.answer.value(LearnNumber.self)!.numeral <= 5 && $0.prompt == "How many beeps?" })

        let letters = questions(.alphabet, .listen)
        let excluded: Set<LearnLetter> = [.k, .q, .x]
        #expect(letters.allSatisfy { q in q.sound == nil && q.choices.allSatisfy { !excluded.contains($0.value(LearnLetter.self)!) } })
        let b = letters.first { $0.answer.value(LearnLetter.self) == .b }!
        #expect(b.prompt == "Which letter does ball start with?")
    }

    @Test func findItPromptCopy() {
        func prompt(_ c: Topic, _ value: some CaseIterable) -> String {
            var rng = SeededGenerator(seed: 26)
            let target = c.item(value)
            let source = c.questionSource(for: .findIt)
            while true {
                let q = source.next(correctCount: 0, excluding: nil, using: &rng)
                if q.answer == target { return q.prompt }
            }
        }
        #expect(prompt(.alphabet, LearnLetter.b) == "Can you find the letter b?")
        #expect(prompt(.numbers, LearnNumber.three) == "Can you find the number Three?")
        #expect(prompt(.animals, LearnAnimal.cow) == "Can you find the Cow?")
        #expect(prompt(.days, DayOfWeek.tuesday) == "Can you find Tuesday?")
        #expect(prompt(.colors, LearnColor.red) == "Can you find Red?")
    }

    @Test func titles() {
        #expect(Game.allCases.map(\.title) == ["Find it!", "Odd one out", "Listen",
                                                "What comes next?", "Week train", "Yesterday and tomorrow",
                                                "Year wheel", "Which season?", "Count with me", "Which has the most?"])
    }

    /// The prompt names the rule, so only one choice fits it.
    @Test func oddOneOutPromptsNameTheRule() {
        let expected: [(Topic, (QuizItem) -> String)] = [
            (.animals, { $0.value(LearnAnimal.self)!.canFly ? "Which one can fly?" : "Which one can't fly?" }),
            (.food, { $0.value(LearnFood.self)!.isFruit ? "Which one is a fruit?" : "Which one is a vegetable?" }),
            (.shapes, { $0.value(LearnShape.self)!.hasCorners! ? "Which one has corners?" : "Which one is round?" }),
        ]
        for (c, prompt) in expected {
            for q in questions(c, .oddOneOut) {
                #expect(q.prompt == prompt(q.answer), "\(c)")
            }
        }
    }

    /// A storm is rain and wind to a child, so it is never offered beside those cues.
    @Test func stormyNotOfferedForRainOrWind() {
        let stormy = Topic.weather.item(LearnWeather.stormy)
        for q in questions(.weather, .listen) where q.answer != stormy {
            #expect(!q.choices.contains(stormy))
        }
    }
}

struct GameSymbolTests {
    @Test(arguments: Game.allCases) func symbolExists(_ game: Game) {
        #expect(UIImage(systemName: game.symbol) != nil)
    }
}
