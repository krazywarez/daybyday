//
//  Game.swift
//  DayByDay
//

nonisolated enum Game: String, CaseIterable {
    case findIt, oddOneOut, listen
    case comesNext, weekTrain, yesterdayTomorrow, yearWheel, whichSeason, counting, most
    case mixColors, trace, dressUp, sortFood, moves

    var title: String {
        switch self {
        case .findIt:    "Find it!"
        case .oddOneOut: "Odd one out"
        case .listen:    "Listen"
        case .comesNext: "What comes next?"
        case .weekTrain: "Week train"
        case .yesterdayTomorrow: "Yesterday and tomorrow"
        case .yearWheel: "Year wheel"
        case .whichSeason: "Which season?"
        case .counting:  "Count with me"
        case .most:      "Which has the most?"
        case .mixColors: "Mix colors"
        case .trace:     "Trace it"
        case .dressUp:   "Dress for the weather"
        case .sortFood:  "Fruit or vegetable?"
        case .moves:     "Move your body"
        }
    }

    var symbol: String {
        switch self {
        case .findIt:    "magnifyingglass"
        case .oddOneOut: "square.grid.2x2.fill"
        case .listen:    "ear.fill"
        case .comesNext: "arrow.right.circle.fill"
        case .weekTrain: "train.side.front.car"
        case .yesterdayTomorrow: "calendar.day.timeline.left"
        case .yearWheel: "circle.dashed"
        case .whichSeason: "leaf.fill"
        case .counting:  "hand.tap.fill"
        case .most:      "chart.bar.fill"
        case .mixColors: "paintbrush.fill"
        case .trace:     "hand.draw.fill"
        case .dressUp:   "tshirt.fill"
        case .sortFood:  "basket.fill"
        case .moves:     "figure.wave"
        }
    }

    /// Played as a `Round` of questions; the rest have their own screens.
    var usesRound: Bool {
        switch self {
        case .findIt, .oddOneOut, .listen, .comesNext, .whichSeason, .most, .mixColors, .dressUp: true
        case .weekTrain, .yesterdayTomorrow, .yearWheel, .counting, .trace, .sortFood, .moves: false
        }
    }
}

nonisolated extension LearnAnimal {
    var sound: SoundEffect? {
        switch self {
        case .cat:   .meow
        case .dog:   .woof
        case .bird:  .tweet
        case .cow:   .moo
        case .duck:  .quack
        case .sheep: .baa
        case .pig:   .oink
        default:     nil
        }
    }
}

nonisolated extension LearnWeather {
    var sound: SoundEffect? {
        switch self {
        case .rainy:  .rain
        case .windy:  .wind
        case .stormy: .thunder
        default:      nil
        }
    }
}

nonisolated extension Category {
    /// Games offered in this topic's hub, in order.
    var games: [Game] {
        var games: [Game] = [.findIt]
        if [.shapes, .animals, .food].contains(self) { games.append(.oddOneOut) }
        if [.numbers, .animals, .alphabet, .weather].contains(self) { games.append(.listen) }
        switch self {
        case .days:          games += [.comesNext, .weekTrain, .yesterdayTomorrow]
        case .months:        games += [.comesNext, .yearWheel]
        case .seasons:       games.append(.whichSeason)
        case .numbers:       games += [.counting, .most]
        case .colors:        games.append(.mixColors)
        case .shapes, .alphabet: games.append(.trace)
        case .weather:       games.append(.dressUp)
        case .food:          games.append(.sortFood)
        case .bodyParts:     games.append(.moves)
        default:             break
        }
        return games
    }

    func questionSource(for game: Game) -> any QuestionSource {
        switch game {
        case .findIt:    findIt
        case .oddOneOut: oddOneOut
        case .listen:    listen
        case .comesNext: ComesNext(items: quizItems, noun: self == .days ? "day" : "month")
        case .whichSeason: WhichSeason()
        case .most:      Most()
        case .mixColors: MixColors()
        case .dressUp:   DressUp()
        case .weekTrain, .yesterdayTomorrow, .yearWheel, .counting, .trace, .sortFood, .moves:
            preconditionFailure("\(game) is not a question round")
        }
    }

    private var findIt: QuestionPicker {
        let article = switch self {
        case .alphabet: "the letter "
        case .numbers: "the number "
        case .animals, .food, .shapes, .bodyParts: "the "
        default: ""
        }
        return QuestionPicker(answers: quizItems) { "Can you find \(article)\($0.name)?" }
    }

    private var oddOneOut: OddOneOut {
        switch self {
        case .food:
            OddOneOut(group(LearnFood.allCases.filter(\.isFruit), "Which one is a fruit?") { "\($0.name) is a fruit." },
                      group(LearnFood.allCases.filter { !$0.isFruit }, "Which one is a vegetable?") { "\($0.name) is a vegetable." })
        case .animals:
            OddOneOut(group(LearnAnimal.allCases.filter(\.canFly), "Which one can fly?") { "\($0.name) can fly." },
                      group(LearnAnimal.allCases.filter { !$0.canFly }, "Which one can't fly?") { "\($0.name) can't fly." })
        case .shapes:
            OddOneOut(group(LearnShape.allCases.filter { $0.hasCorners == false }, "Which one is round?") { "\($0.name) is round." },
                      group(LearnShape.allCases.filter { $0.hasCorners == true }, "Which one has corners?") { "\($0.name) has corners." })
        default:
            preconditionFailure("No odd one out for \(self)")
        }
    }

    private var listen: QuestionPicker {
        switch self {
        case .animals:
            let voiced = items(LearnAnimal.allCases.filter { $0.sound != nil })
            return QuestionPicker(answers: voiced, prompt: { _ in "Who says this?" },
                                  sound: { $0.value(LearnAnimal.self)?.sound })
        case .weather:
            return QuestionPicker(answers: items(LearnWeather.allCases.filter { $0.sound != nil }),
                                  // Stormy only as an answer: a storm is also rain and wind.
                                  distractors: items(LearnWeather.allCases.filter { $0 != .stormy }),
                                  prompt: { _ in "What weather sounds like this?" },
                                  sound: { $0.value(LearnWeather.self)?.sound })
        case .numbers:
            return QuestionPicker(answers: items(LearnNumber.allCases.filter { $0.numeral <= 5 }),
                                  prompt: { _ in "How many beeps?" },
                                  sound: { $0.value(LearnNumber.self).map { .beeps($0.numeral) } })
        case .alphabet:
            // K and Q share C's sound in their example words; X has no starting sound.
            let letters = items(LearnLetter.allCases.filter { ![.k, .q, .x].contains($0) })
            return QuestionPicker(answers: letters) {
                "Which letter does \($0.value(LearnLetter.self)!.exampleWord) start with?"
            }
        default:
            preconditionFailure("No listening game for \(self)")
        }
    }

    private func items<T: CaseIterable>(_ values: [T]) -> [QuizItem] {
        values.map { item($0) }
    }

    private func group<T: CaseIterable>(_ values: [T], _ question: String,
                                        fact: @escaping (QuizItem) -> String) -> OddOneOut.Group {
        OddOneOut.Group(members: items(values), question: question, fact: fact)
    }
}
