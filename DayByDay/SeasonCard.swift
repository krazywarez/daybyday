//
//  SeasonCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one season.
/// Tapping the card plays a bounce animation and speaks the season name aloud.
struct SeasonCard: View {
    let season: Season
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
                .fill(season.color)
                .shadow(color: season.color.opacity(0.4), radius: 8, y: 4)
                // Glow on the card only: on the label it would lower the contrast.
                .shadow(color: isHighlighted ? .white.opacity(0.8) : .clear, radius: 12)

            VStack(spacing: 16) {
                Image(systemName: season.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(season.name)
                    .font(.heading(32))
                    .foregroundStyle(.white)
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
            SpeechSynthesizer.shared.speak(season.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(season.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Season model

nonisolated enum Season: Int, CaseIterable, Identifiable {
    case spring, summer, fall, winter

    var id: Int { rawValue }

    /// The season for today's date.
    /// Spring: March–May, Summer: June–August,
    /// Fall: September–November, Winter: December–February.
    static var current: Season {
        let month = AppCalendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return .spring
        case 6...8:  return .summer
        case 9...11: return .fall
        default:     return .winter
        }
    }

    var name: String {
        switch self {
        case .spring: "Spring"
        case .summer: "Summer"
        case .fall:   "Fall"
        case .winter: "Winter"
        }
    }

    var symbol: String {
        switch self {
        case .spring: "leaf.fill"
        case .summer: "sun.max.fill"
        case .fall:   "wind"
        case .winter: "snowflake"
        }
    }

    var color: Color {
        switch self {
        case .spring: Color(red: 0.35, green: 0.61, blue: 0.38)   // fresh green
        case .summer: Color(red: 0.79, green: 0.47, blue: 0.12)   // sunny orange
        case .fall:   Color(red: 0.84, green: 0.45, blue: 0.2)  // autumn orange
        case .winter: Color(red: 0.35, green: 0.56, blue: 0.82)  // cool blue
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        SeasonCard(season: .spring, isHighlighted: true)
            .frame(width: 200, height: 260)
        SeasonCard(season: .summer)
            .frame(width: 200, height: 260)
    }
    .padding()
}
