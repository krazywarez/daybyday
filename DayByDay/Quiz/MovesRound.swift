//
//  MovesRound.swift
//  DayByDay
//

nonisolated extension LearnBodyPart {
    /// Something to do with this part, said aloud.
    var command: String {
        switch self {
        case .head:    "Touch your head!"
        case .eyes:    "Blink your eyes!"
        case .ears:    "Touch your ears!"
        case .nose:    "Touch your nose!"
        case .mouth:   "Point to your mouth!"
        case .hands:   "Clap your hands!"
        case .fingers: "Wiggle your fingers!"
        case .arms:    "Wave your arms!"
        case .legs:    "March in place!"
        case .feet:    "Stomp your feet!"
        case .heart:   "Put your hand on your heart!"
        case .belly:   "Pat your belly!"
        }
    }
}

/// Five different moves, one after another.
nonisolated struct MovesRound {
    static let length = 5

    let parts: [LearnBodyPart]
    private(set) var index = 0

    init(using rng: inout some RandomNumberGenerator) {
        parts = Array(LearnBodyPart.allCases.shuffled(using: &rng).prefix(Self.length))
    }

    var current: LearnBodyPart? { index < parts.count ? parts[index] : nil }
    var isDone: Bool { current == nil }

    mutating func next() {
        if index < parts.count { index += 1 }
    }
}
