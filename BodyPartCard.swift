//
//  BodyPartCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one body part.
/// Tapping the card plays a bounce animation and speaks the body part name aloud.
struct BodyPartCard: View {
    let bodyPart: LearnBodyPart
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(bodyPart.color)
                .shadow(color: bodyPart.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                Image(systemName: bodyPart.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(bodyPart.name)
                    .font(.heading(32))
                    .foregroundStyle(.white)
            }
            .padding(16)
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(bodyPart.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bodyPart.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Body part model

nonisolated enum LearnBodyPart: Int, CaseIterable, Identifiable {
    case head, eyes, ears, nose, mouth, hands, fingers, arms, legs, feet, heart, belly

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .head:    "Head"
        case .eyes:    "Eyes"
        case .ears:    "Ears"
        case .nose:    "Nose"
        case .mouth:   "Mouth"
        case .hands:   "Hands"
        case .fingers: "Fingers"
        case .arms:    "Arms"
        case .legs:    "Legs"
        case .feet:    "Feet"
        case .heart:   "Heart"
        case .belly:   "Belly"
        }
    }

    var symbol: String {
        switch self {
        case .head:    "brain.head.profile"
        case .eyes:    "eye.fill"
        case .ears:    "ear.fill"
        case .nose:    "nose.fill"
        case .mouth:   "mouth.fill"
        case .hands:   "hand.raised.fill"
        case .fingers: "hand.point.up.fill"
        case .arms:    "figure.arms.open"
        case .legs:    "figure.walk"
        case .feet:    "shoeprints.fill"
        case .heart:   "heart.fill"
        case .belly:   "circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .head:    Color(red: 0.82, green: 0.46, blue: 0.27)    // warm orange
        case .eyes:    Color(red: 0.26, green: 0.58, blue: 0.8)   // blue
        case .ears:    Color(red: 0.6, green: 0.45, blue: 0.85)  // purple
        case .nose:    Color(red: 0.88, green: 0.39, blue: 0.49)    // rose
        case .mouth:   Color(red: 0.9, green: 0.3, blue: 0.35)   // red
        case .hands:   Color(red: 0.71, green: 0.52, blue: 0.22)   // golden
        case .fingers: Color(red: 0.28, green: 0.61, blue: 0.41)  // green
        case .arms:    Color(red: 0.21, green: 0.61, blue: 0.61)   // teal
        case .legs:    Color(red: 0.5, green: 0.4, blue: 0.8)    // indigo
        case .feet:    Color(red: 0.7, green: 0.5, blue: 0.3)    // brown
        case .heart:   Color(red: 0.85, green: 0.3, blue: 0.45)  // deep pink
        case .belly:   Color(red: 0.79, green: 0.47, blue: 0.32)    // peach
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        BodyPartCard(bodyPart: .head)
            .frame(width: 200, height: 260)
        BodyPartCard(bodyPart: .hands)
            .frame(width: 200, height: 260)
    }
    .padding()
}
