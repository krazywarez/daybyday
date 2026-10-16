//
//  Counting.swift
//  DayByDay
//

/// "Count with me": five sets of 1 to 10 objects; the child taps each once.
nonisolated struct CountingRound {
    static let length = 5

    struct Thing: Equatable {
        let symbol: String
        let singular: String
        let plural: String
    }

    static let things = [
        Thing(symbol: "star.fill", singular: "star", plural: "stars"),
        Thing(symbol: "heart.fill", singular: "heart", plural: "hearts"),
        Thing(symbol: "leaf.fill", singular: "leaf", plural: "leaves"),
        Thing(symbol: "moon.fill", singular: "moon", plural: "moons"),
        Thing(symbol: "fish.fill", singular: "fish", plural: "fish"),
    ]

    private(set) var target: Int
    private(set) var thing: Thing
    /// Object indices in the order they were tapped.
    private(set) var counted: [Int] = []
    private(set) var setsDone = 0

    var isSetDone: Bool { counted.count == target }
    var isComplete: Bool { setsDone == Self.length }

    init(using rng: inout some RandomNumberGenerator) {
        self.init(target: Int.random(in: 1...10, using: &rng),
                  thing: Self.things.randomElement(using: &rng)!, using: &rng)
    }

    init(target: Int, thing: Thing, using rng: inout some RandomNumberGenerator) {
        precondition((1...10).contains(target))
        self.target = target
        self.thing = thing
    }

    /// The new count, or nil if `index` is not an uncounted object.
    mutating func tap(_ index: Int) -> Int? {
        guard !isSetDone, (0..<target).contains(index), !counted.contains(index) else { return nil }
        counted.append(index)
        return counted.count
    }

    /// Starts the next set once this one is counted.
    mutating func nextSet(using rng: inout some RandomNumberGenerator) {
        guard isSetDone, !isComplete else { return }
        setsDone += 1
        guard !isComplete else { return }
        let previous = target
        target = (1...10).filter { $0 != previous }.randomElement(using: &rng)!
        thing = Self.things.filter { $0 != thing }.randomElement(using: &rng)!
        counted = []
    }

    func summary() -> String {
        let word = LearnNumber(rawValue: target)!.name
        return target == 1
            ? "\(word)! There is one \(thing.singular)."
            : "\(word)! There are \(word.lowercased()) \(thing.plural)."
    }
}
