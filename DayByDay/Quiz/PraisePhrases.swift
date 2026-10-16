//
//  PraisePhrases.swift
//  DayByDay
//

nonisolated struct PraisePhrases {
    static let all = [
        "Great job!",
        "You got it!",
        "Super!",
        "Way to go!",
        "Awesome!",
        "Yes, that's right!",
        "Nice work!",
        "You did great!",
        "Hooray!",
        "Fantastic!",
    ]

    private var last: String?

    /// A random phrase, never the same as the previous one.
    mutating func next(using rng: inout some RandomNumberGenerator) -> String {
        let phrase = Self.all.filter { $0 != last }.randomElement(using: &rng)!
        last = phrase
        return phrase
    }

    static func correction(for name: String) -> String {
        "That's \(name)! Try again."
    }
}
