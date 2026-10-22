//
//  AnimalCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one animal.
/// Tapping the card plays a bounce animation and speaks the animal name aloud.
struct AnimalCard: View {
    let animal: LearnAnimal

    var body: some View {
        TapCard(color: animal.color, label: animal.name) {
            CardVoice.shared.say(animal.cardLine, after: animal.sound)
        } content: {
            VStack(spacing: 16) {
                AnimalIcon(animal: animal)
                    .font(.system(size: 64))
                    .frame(height: 72)
                    .foregroundStyle(.white)

                Text(animal.name)
                    .font(.heading(32))
                    .foregroundStyle(.white)
            }
            .padding(16)
        }
    }
}

// MARK: - Animal model

nonisolated enum LearnAnimal: Int, CaseIterable, Identifiable {
    case cat, dog, bird, fish, rabbit, turtle, ladybug, cow, duck, sheep, pig

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .cat:       "Cat"
        case .dog:       "Dog"
        case .bird:      "Bird"
        case .fish:      "Fish"
        case .rabbit:    "Rabbit"
        case .turtle:    "Turtle"
        case .ladybug:   "Ladybug"
        case .cow:       "Cow"
        case .duck:      "Duck"
        case .sheep:     "Sheep"
        case .pig:       "Pig"
        }
    }

    /// Nil for animals without an SF Symbol; `AnimalIcon` draws those.
    var symbol: String? {
        switch self {
        case .cat:       "cat.fill"
        case .dog:       "dog.fill"
        case .bird:      "bird.fill"
        case .fish:      "fish.fill"
        case .rabbit:    "hare.fill"
        case .turtle:    "tortoise.fill"
        case .ladybug:   "ladybug.fill"
        case .cow, .duck, .sheep, .pig: nil
        }
    }

    /// At least 3:1 against the white icon and name.
    var color: Color {
        switch self {
        case .cat:       Color(red: 0.80, green: 0.42, blue: 0.08)  // orange
        case .dog:       Color(red: 0.55, green: 0.38, blue: 0.22)  // brown
        case .bird:      Color(red: 0.10, green: 0.48, blue: 0.78)  // sky blue
        case .fish:      Color(red: 0.0, green: 0.53, blue: 0.56)   // teal
        case .rabbit:    Color(red: 0.55, green: 0.40, blue: 0.70)  // lavender
        case .turtle:    Color(red: 0.18, green: 0.56, blue: 0.28)  // green
        case .ladybug:   Color(red: 0.86, green: 0.20, blue: 0.22)  // red
        case .cow:       Color(red: 0.35, green: 0.38, blue: 0.45)  // slate
        case .duck:      Color(red: 0.66, green: 0.50, blue: 0.0)   // mustard
        case .sheep:     Color(red: 0.40, green: 0.45, blue: 0.55)  // blue gray
        case .pig:       Color(red: 0.82, green: 0.25, blue: 0.52)  // pink
        }
    }

    var fact: String {
        switch self {
        case .cat:     "Cats say meow."
        case .dog:     "Dogs say woof."
        case .bird:    "Birds can fly."
        case .fish:    "Fish swim in water."
        case .rabbit:  "Rabbits hop."
        case .turtle:  "Turtles carry their shell."
        case .ladybug: "Ladybugs have spots."
        case .cow:     "Cows say moo."
        case .duck:    "Ducks say quack."
        case .sheep:   "Sheep say baa."
        case .pig:     "Pigs say oink."
        }
    }

    /// Said when the card is tapped, after the animal's sound.
    var cardLine: String { "\(name)! \(fact)" }

    var canFly: Bool {
        switch self {
        case .bird, .ladybug, .duck: true
        default: false
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        AnimalCard(animal: .cat)
            .frame(width: 200, height: 260)
    }
    .padding()
}
