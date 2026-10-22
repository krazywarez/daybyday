//
//  MonthCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one month of the year.
/// Tapping the card plays a bounce animation and speaks the month name aloud.
struct MonthCard: View {
    let month: MonthOfYear
    var isHighlighted = false

    var body: some View {
        TapCard(color: month.color, label: month.name, isHighlighted: isHighlighted) {
            SpeechSynthesizer.shared.speak(month.name)
        } content: {
            SymbolLabel(symbol: month.symbol, name: month.name)
        }
    }
}

// MARK: - Month model

nonisolated enum MonthOfYear: Int, CaseIterable, Identifiable {
    case january, february, march, april, may, june,
         july, august, september, october, november, december

    var id: Int { rawValue }

    /// The month for today's date.
    static var current: MonthOfYear {
        // Calendar month: 1 = January, 12 = December
        let month = AppCalendar.current.component(.month, from: Date())
        return MonthOfYear(rawValue: month - 1)!
    }

    var name: String {
        switch self {
        case .january:   "January"
        case .february:  "February"
        case .march:     "March"
        case .april:     "April"
        case .may:       "May"
        case .june:      "June"
        case .july:      "July"
        case .august:    "August"
        case .september: "September"
        case .october:   "October"
        case .november:  "November"
        case .december:  "December"
        }
    }

    var symbol: String {
        switch self {
        case .january:   "snowflake"
        case .february:  "heart.fill"
        case .march:     "wind"
        case .april:     "cloud.rain.fill"
        case .may:       "leaf.fill"
        case .june:      "sun.max.fill"
        case .july:      "fireworks"
        case .august:    "beach.umbrella.fill"
        case .september: "book.fill"
        case .october:   "moon.stars.fill"
        case .november:  "fork.knife"
        case .december:  "gift.fill"
        }
    }

    var color: Color {
        switch self {
        case .january:   Color(red: 0.42, green: 0.56, blue: 0.72) // ice blue
        case .february:  Color(red: 0.9, green: 0.35, blue: 0.5)   // pink
        case .march:     Color(red: 0.35, green: 0.6, blue: 0.41)  // spring green
        case .april:     Color(red: 0.43, green: 0.55, blue: 0.77)   // rain blue
        case .may:       Color(red: 0.71, green: 0.52, blue: 0.15)   // golden
        case .june:      Color(red: 0.83, green: 0.45, blue: 0.2)  // warm orange
        case .july:      Color(red: 0.85, green: 0.25, blue: 0.3)  // red
        case .august:    Color(red: 0.16, green: 0.6, blue: 0.64)   // ocean teal
        case .september: Color(red: 0.6, green: 0.45, blue: 0.85)  // purple
        case .october:   Color(red: 0.82, green: 0.46, blue: 0.14)   // pumpkin
        case .november:  Color(red: 0.7, green: 0.5, blue: 0.3)    // brown
        case .december:  Color(red: 0.3, green: 0.5, blue: 0.85)   // winter blue
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        MonthCard(month: .march, isHighlighted: true)
            .frame(width: 200, height: 260)
        MonthCard(month: .april)
            .frame(width: 200, height: 260)
    }
    .padding()
}
