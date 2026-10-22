//
//  WeatherCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one weather type.
/// Tapping the card plays a bounce animation and speaks the weather name aloud.
struct WeatherCard: View {
    let weather: LearnWeather

    var body: some View {
        TapCard(color: weather.color, label: weather.name) {
            SpeechSynthesizer.shared.speak(weather.name)
        } content: {
            SymbolLabel(symbol: weather.symbol, name: weather.name)
        }
    }
}

// MARK: - Weather model

nonisolated enum LearnWeather: Int, CaseIterable, Identifiable {
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
        case .sunny:   Color(red: 0.73, green: 0.51, blue: 0.15)    // orange
        case .cloudy:  Color(red: 0.55, green: 0.55, blue: 0.6)   // gray
        case .rainy:   Color(red: 0.28, green: 0.57, blue: 0.85)    // blue
        case .snowy:   Color(red: 0.4, green: 0.57, blue: 0.68)  // light blue
        case .windy:   Color(red: 0.21, green: 0.61, blue: 0.61)   // teal
        case .stormy:  Color(red: 0.2, green: 0.3, blue: 0.6)    // dark blue
        case .foggy:   Color(red: 0.6, green: 0.5, blue: 0.7)    // muted purple
        case .rainbow: Color(red: 0.83, green: 0.42, blue: 0.56)   // pink
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
