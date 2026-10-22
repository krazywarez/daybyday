//
//  DayCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one day of the week.
/// Tapping the card plays a bounce animation and speaks the day name aloud,
/// plus the child's day picture when there is one ("It's swim day!").
struct DayCard: View {
    let day: DayOfWeek
    var isHighlighted = false
    var picture: DayPictureKind? = nil

    var body: some View {
        TapCard(
            color: day.color,
            label: picture.map { "\(day.name), \($0.name)" } ?? day.name,
            isHighlighted: isHighlighted
        ) {
            CardVoice.shared.say(Lines.dayCard(day, picture: picture), after: nil)
        } content: {
            SymbolLabel(symbol: day.symbol, name: day.name)
        } badge: {
            if let picture {
                Image(systemName: picture.symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(day.color)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.white))
                    .padding(14)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Day model

nonisolated enum DayOfWeek: Int, CaseIterable, Identifiable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    /// The day of the week for today's date.
    static var current: DayOfWeek {
        // Calendar weekday: 1 = Sunday, 7 = Saturday
        let weekday = AppCalendar.current.component(.weekday, from: Date())
        return DayOfWeek(rawValue: weekday - 1)!
    }

    var name: String {
        switch self {
        case .sunday:    "Sunday"
        case .monday:    "Monday"
        case .tuesday:   "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday:  "Thursday"
        case .friday:    "Friday"
        case .saturday:  "Saturday"
        }
    }

    /// A recognisable SF Symbol icon for each day so children who cannot read
    /// still get a unique visual cue.
    var symbol: String {
        switch self {
        case .sunday:    "sun.max.fill"
        case .monday:    "moon.fill"
        case .tuesday:   "star.fill"
        case .wednesday: "cloud.fill"
        case .thursday:  "bolt.fill"
        case .friday:    "heart.fill"
        case .saturday:  "sparkles"
        }
    }

    /// A color per day, each at least 3:1 against the white icon and name.
    var color: Color {
        switch self {
        case .sunday:    Color(red: 0.80, green: 0.42, blue: 0.08)  // orange
        case .monday:    Color(red: 0.25, green: 0.42, blue: 0.85)  // blue
        case .tuesday:   Color(red: 0.84, green: 0.22, blue: 0.34)  // red-pink
        case .wednesday: Color(red: 0.18, green: 0.56, blue: 0.28)  // green
        case .thursday:  Color(red: 0.55, green: 0.4, blue: 0.85)   // purple
        case .friday:    Color(red: 0.66, green: 0.50, blue: 0.0)   // mustard
        case .saturday:  Color(red: 0.0, green: 0.53, blue: 0.56)   // teal
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        DayCard(day: .wednesday, isHighlighted: true)
            .frame(width: 200, height: 260)
        DayCard(day: .thursday)
            .frame(width: 200, height: 260)
    }
    .padding()
}
