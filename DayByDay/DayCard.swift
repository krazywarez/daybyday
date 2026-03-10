//
//  DayCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one day of the week.
/// Tapping the card plays a bounce animation and speaks the day name aloud.
struct DayCard: View {
    let day: DayOfWeek
    var isHighlighted = false
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(day.color.gradient)
                .shadow(color: day.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                Image(systemName: day.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(day.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white, lineWidth: 5)
            }
        }
        .shadow(color: isHighlighted ? .white.opacity(0.8) : .clear, radius: 12)
        .scaleEffect(isTapped ? 1.12 : (isHighlighted ? 1.04 : 1.0))
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(day.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityLabel(day.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Day model

enum DayOfWeek: Int, CaseIterable, Identifiable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    /// The day of the week for today's date.
    static var current: DayOfWeek {
        // Calendar weekday: 1 = Sunday, 7 = Saturday
        let weekday = Calendar.current.component(.weekday, from: Date())
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

    /// Bright, child-friendly colour for each card.
    var color: Color {
        switch self {
        case .sunday:    Color(red: 1.0, green: 0.6, blue: 0.2)   // orange
        case .monday:    Color(red: 0.35, green: 0.5, blue: 0.9)  // blue
        case .tuesday:   Color(red: 0.9, green: 0.3, blue: 0.4)   // red-pink
        case .wednesday: Color(red: 0.3, green: 0.75, blue: 0.45) // green
        case .thursday:  Color(red: 0.55, green: 0.4, blue: 0.9)  // purple
        case .friday:    Color(red: 1.0, green: 0.8, blue: 0.2)   // yellow
        case .saturday:  Color(red: 0.2, green: 0.8, blue: 0.8)   // teal
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
