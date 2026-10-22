//
//  ColorCard.swift
//  DayByDay
//

import SwiftUI

/// A single large card filled with a color. Tapping speaks the color name aloud.
struct ColorCard: View {
    let learnColor: LearnColor

    var body: some View {
        TapCard(color: learnColor.color, label: learnColor.name) {
            SpeechSynthesizer.shared.speak(learnColor.name)
        } content: {
            Text(learnColor.name)
                .font(.heading(36))
                .foregroundStyle(learnColor.labelColor)
        }
    }
}

// MARK: - Color model

nonisolated enum LearnColor: Int, CaseIterable, Identifiable {
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

    /// White or black, whichever is at least 3:1 on the color.
    var labelColor: Color {
        switch self {
        case .orange, .yellow, .green, .pink, .white: .black
        default: .white
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
