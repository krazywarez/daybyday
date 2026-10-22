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

    var body: some View {
        TapCard(color: season.color, label: season.name, isHighlighted: isHighlighted) {
            SpeechSynthesizer.shared.speak(season.name)
        } content: {
            SymbolLabel(symbol: season.symbol, name: season.name)
        }
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
