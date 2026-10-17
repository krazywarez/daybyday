//
//  MascotState.swift
//  DayByDay
//

import Foundation

nonisolated enum MascotMood: CaseIterable {
    case idle, asking, cheering, puzzled, waving
}

/// Something in a game the mascot reacts to.
nonisolated enum MascotEvent: Equatable {
    /// A prompt being said, after an optional sound cue.
    case prompt(String, after: TimeInterval = 0)
    case correct
    case wrong
    case greet
}

/// The mascot's mood in a game. Each event sets a mood that holds for a
/// while, then `settle` puts it back to idle unless a newer event came in.
nonisolated struct MascotState: Equatable {
    private(set) var mood: MascotMood = .idle
    /// Bumped by every event, so a settle for an older one does nothing.
    private(set) var ticket = 0
    private(set) var hold: TimeInterval = 0

    mutating func handle(_ event: MascotEvent) {
        switch event {
        case .prompt: mood = .asking
        case .correct: mood = .cheering
        case .wrong: mood = .puzzled
        case .greet: mood = .waving
        }
        ticket += 1
        hold = Self.hold(for: event)
    }

    mutating func settle(_ ticket: Int) {
        if ticket == self.ticket { mood = .idle }
    }

    /// How long the event's mood lasts. A prompt lasts through its sound cue
    /// and roughly as long as it takes to say.
    static func hold(for event: MascotEvent) -> TimeInterval {
        switch event {
        case .prompt(let text, let delay): delay + 0.5 + 0.45 * Double(text.split(separator: " ").count)
        case .correct: 1.8
        case .wrong: 1.6
        case .greet: 2.4
        }
    }
}
