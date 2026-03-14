//
//  LetterCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one letter of the alphabet.
/// Tapping the card plays a bounce animation and speaks the letter aloud.
struct LetterCard: View {
    let letter: LearnLetter
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(letter.color.gradient)
                .shadow(color: letter.color.opacity(0.4), radius: 8, y: 4)

            Text(letter.character)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(letter.spokenName)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityLabel(letter.spokenName)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Letter model

enum LearnLetter: Int, CaseIterable, Identifiable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m,
         n, o, p, q, r, s, t, u, v, w, x, y, z

    var id: Int { rawValue }

    var character: String {
        String(Character(UnicodeScalar(65 + rawValue)!))
    }

    /// Speak the letter name clearly for a child.
    /// Lowercase prevents TTS from saying "Capital A".
    var spokenName: String {
        character.lowercased()
    }

    /// Cycle through 8 bright colors to give variety without unique-per-letter mapping.
    var color: Color {
        let palette: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.3),   // red
            Color(red: 1.0, green: 0.55, blue: 0.2),   // orange
            Color(red: 1.0, green: 0.8, blue: 0.2),    // yellow
            Color(red: 0.35, green: 0.75, blue: 0.4),   // green
            Color(red: 0.2, green: 0.65, blue: 0.9),    // blue
            Color(red: 0.55, green: 0.4, blue: 0.85),   // purple
            Color(red: 0.85, green: 0.4, blue: 0.6),    // pink
            Color(red: 0.2, green: 0.75, blue: 0.75),   // teal
        ]
        return palette[rawValue % palette.count]
    }
}

#Preview {
    HStack(spacing: 24) {
        LetterCard(letter: .a)
            .frame(width: 140, height: 160)
        LetterCard(letter: .b)
            .frame(width: 140, height: 160)
        LetterCard(letter: .c)
            .frame(width: 140, height: 160)
    }
    .padding()
}
