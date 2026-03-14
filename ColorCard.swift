//
//  ColorCard.swift
//  DayByDay
//

import SwiftUI

/// A single large card filled with a color. Tapping speaks the color name aloud.
struct ColorCard: View {
    let learnColor: LearnColor
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(learnColor.color.gradient)
                .shadow(color: learnColor.color.opacity(0.4), radius: 8, y: 4)

            Text(learnColor.name)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(learnColor.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityLabel(learnColor.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Color model

enum LearnColor: Int, CaseIterable, Identifiable {
    case red, orange, yellow, green, blue, purple, pink, brown, black, white

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .red:    "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green:  "Green"
        case .blue:   "Blue"
        case .purple: "Purple"
        case .pink:   "Pink"
        case .brown:  "Brown"
        case .black:  "Black"
        case .white:  "White"
        }
    }

    var color: Color {
        switch self {
        case .red:    Color(red: 0.9, green: 0.2, blue: 0.2)
        case .orange: Color(red: 1.0, green: 0.55, blue: 0.15)
        case .yellow: Color(red: 1.0, green: 0.82, blue: 0.15)
        case .green:  Color(red: 0.2, green: 0.75, blue: 0.35)
        case .blue:   Color(red: 0.2, green: 0.45, blue: 0.9)
        case .purple: Color(red: 0.55, green: 0.3, blue: 0.85)
        case .pink:   Color(red: 0.95, green: 0.4, blue: 0.6)
        case .brown:  Color(red: 0.55, green: 0.35, blue: 0.2)
        case .black:  Color(red: 0.15, green: 0.15, blue: 0.15)
        case .white:  Color(red: 0.92, green: 0.92, blue: 0.92)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ColorCard(learnColor: .red)
            .frame(width: 200, height: 200)
        ColorCard(learnColor: .blue)
            .frame(width: 200, height: 200)
    }
    .padding()
}
