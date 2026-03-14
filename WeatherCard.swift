//
//  WeatherCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one weather type.
/// Tapping the card plays a bounce animation and speaks the weather name aloud.
struct WeatherCard: View {
    let weather: LearnWeather
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(weather.color.gradient)
                .shadow(color: weather.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                Image(systemName: weather.symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(weather.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(weather.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityLabel(weather.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Weather model

enum LearnWeather: Int, CaseIterable, Identifiable {
    case sunny, cloudy, rainy, snowy, windy, stormy, foggy, rainbow

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunny:   "Sunny"
        case .cloudy:  "Cloudy"
        case .rainy:   "Rainy"
        case .snowy:   "Snowy"
        case .windy:   "Windy"
        case .stormy:  "Stormy"
        case .foggy:   "Foggy"
        case .rainbow: "Rainbow"
        }
    }

    var symbol: String {
        switch self {
        case .sunny:   "sun.max.fill"
        case .cloudy:  "cloud.fill"
        case .rainy:   "cloud.rain.fill"
        case .snowy:   "cloud.snow.fill"
        case .windy:   "wind"
        case .stormy:  "cloud.bolt.rain.fill"
        case .foggy:   "cloud.fog.fill"
        case .rainbow: "rainbow"
        }
    }

    var color: Color {
        switch self {
        case .sunny:   Color(red: 1.0, green: 0.7, blue: 0.2)    // orange
        case .cloudy:  Color(red: 0.6, green: 0.6, blue: 0.65)   // gray
        case .rainy:   Color(red: 0.3, green: 0.6, blue: 0.9)    // blue
        case .snowy:   Color(red: 0.55, green: 0.8, blue: 0.95)  // light blue
        case .windy:   Color(red: 0.25, green: 0.7, blue: 0.7)   // teal
        case .stormy:  Color(red: 0.2, green: 0.3, blue: 0.6)    // dark blue
        case .foggy:   Color(red: 0.6, green: 0.5, blue: 0.7)    // muted purple
        case .rainbow: Color(red: 0.9, green: 0.45, blue: 0.6)   // pink
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        WeatherCard(weather: .sunny)
            .frame(width: 200, height: 260)
        WeatherCard(weather: .stormy)
            .frame(width: 200, height: 260)
    }
    .padding()
}
