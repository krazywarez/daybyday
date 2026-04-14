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
                .fill(season.color.gradient)
                .shadow(color: season.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                Image(systemName: season.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(season.name)
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
        .accessibilityLabel(season.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Season model

enum Season: Int, CaseIterable, Identifiable {
    case spring, summer, fall, winter

    var id: Int { rawValue }

    /// The season for today's date.
    /// Spring: March–May, Summer: June–August,
    /// Fall: September–November, Winter: December–February.
    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
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
        case .spring: Color(red: 0.45, green: 0.8, blue: 0.5)   // fresh green
        case .summer: Color(red: 1.0, green: 0.6, blue: 0.15)   // sunny orange
        case .fall:   Color(red: 0.85, green: 0.45, blue: 0.2)  // autumn orange
        case .winter: Color(red: 0.4, green: 0.65, blue: 0.95)  // cool blue
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
