//
//  AnimalCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one animal.
/// Tapping the card plays a bounce animation and speaks the animal name aloud.
struct AnimalCard: View {
    let animal: LearnAnimal
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(animal.color.gradient)
                .shadow(color: animal.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                Image(systemName: animal.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(animal.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(animal.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityLabel(animal.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Animal model

enum LearnAnimal: Int, CaseIterable, Identifiable {
    case cat, dog, bird, fish, rabbit, turtle, ladybug, ant, lizard

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
        case .ant:       "Ant"
        case .lizard:    "Lizard"
        }
    }

    var symbol: String {
        switch self {
        case .cat:       "cat.fill"
        case .dog:       "dog.fill"
        case .bird:      "bird.fill"
        case .fish:      "fish.fill"
        case .rabbit:    "hare.fill"
        case .turtle:    "tortoise.fill"
        case .ladybug:   "ladybug.fill"
        case .ant:       "ant.fill"
        case .lizard:    "lizard.fill"
        }
    }

    var color: Color {
        switch self {
        case .cat:       Color(red: 0.9, green: 0.55, blue: 0.2)   // orange
        case .dog:       Color(red: 0.6, green: 0.45, blue: 0.3)   // brown
        case .bird:      Color(red: 0.3, green: 0.65, blue: 0.9)   // sky blue
        case .fish:      Color(red: 0.2, green: 0.75, blue: 0.8)   // teal
        case .rabbit:    Color(red: 0.75, green: 0.6, blue: 0.8)   // lavender
        case .turtle:    Color(red: 0.35, green: 0.7, blue: 0.4)   // green
        case .ladybug:   Color(red: 0.9, green: 0.25, blue: 0.25)  // red
        case .ant:       Color(red: 0.3, green: 0.3, blue: 0.3)    // dark gray
        case .lizard:    Color(red: 0.45, green: 0.75, blue: 0.35)  // lime
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
