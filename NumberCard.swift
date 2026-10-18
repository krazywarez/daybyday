//
//  NumberCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one number (1–10).
/// Tapping the card plays a bounce animation and speaks the number name aloud.
struct NumberCard: View {
    let number: LearnNumber
    var isHighlighted = false
    @State private var isTapped = false

    private var cardScale: CGFloat {
        if isTapped { return 1.12 }
        if isHighlighted { return 1.04 }
        return 1.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(number.color)
                .shadow(color: number.color.opacity(0.4), radius: 8, y: 4)
                // Glow on the card only: on the label it would lower the contrast.
                .shadow(color: isHighlighted ? .white.opacity(0.8) : .clear, radius: 12)

            VStack(spacing: 10) {
                Text("\(number.numeral)")
                    .font(.heading(60, weight: .heavy))
                    .foregroundStyle(.white)

                Text(number.name)
                    .font(.heading(28))
                    .foregroundStyle(.white)

                // Dot pattern showing the quantity
                DotPattern(count: number.numeral)
                    .padding(.top, 4)
            }
            .padding(16)
        }
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white, lineWidth: 5)
            }
        }
        .scaleEffect(cardScale)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(number.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(number.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Number model

nonisolated enum LearnNumber: Int, CaseIterable, Identifiable {
    case one = 1, two, three, four, five, six, seven, eight, nine, ten

    var id: LearnNumber { self }

    /// Highlight the number matching today's day-of-month if it falls in 1–10.
    static var current: LearnNumber? {
        let day = AppCalendar.current.component(.day, from: Date())
        return LearnNumber(rawValue: day)
    }

    var numeral: Int { rawValue }

    var name: String {
        switch self {
        case .one:   "One"
        case .two:   "Two"
        case .three: "Three"
        case .four:  "Four"
        case .five:  "Five"
        case .six:   "Six"
        case .seven: "Seven"
        case .eight: "Eight"
        case .nine:  "Nine"
        case .ten:   "Ten"
        }
    }

    var color: Color {
        switch self {
        case .one:   Color(red: 0.9, green: 0.3, blue: 0.3)   // red
        case .two:   Color(red: 0.83, green: 0.45, blue: 0.16)  // orange
        case .three: Color(red: 0.67, green: 0.53, blue: 0.14)   // yellow
        case .four:  Color(red: 0.29, green: 0.62, blue: 0.33)  // green
        case .five:  Color(red: 0.17, green: 0.6, blue: 0.72)   // sky blue
        case .six:   Color(red: 0.4, green: 0.45, blue: 0.9)   // blue
        case .seven: Color(red: 0.6, green: 0.4, blue: 0.85)   // purple
        case .eight: Color(red: 0.85, green: 0.35, blue: 0.6)  // pink
        case .nine:  Color(red: 0.4, green: 0.6, blue: 0.36)  // lime
        case .ten:   Color(red: 0.19, green: 0.61, blue: 0.57)  // teal
        }
    }
}

// MARK: - Dot pattern

/// Displays a grid of filled circles representing a quantity.
/// 1–5 dots use centered rows; 6–10 use a 5-column grid that wraps naturally.
struct DotPattern: View {
    let count: Int

    private var columns: [GridItem] {
        let maxCols = count <= 5 ? min(count, 5) : 5
        return Array(repeating: GridItem(.fixed(14), spacing: 6), count: maxCols)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 14, height: 14)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack(spacing: 24) {
        NumberCard(number: .three, isHighlighted: true)
            .frame(width: 280, height: 300)
        NumberCard(number: .seven)
            .frame(width: 280, height: 300)
    }
    .padding()
}
