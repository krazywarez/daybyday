//
//  WeatherView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 8 weather types as large, tappable cards in a scrollable grid.
/// Shaking the device, or tapping the rain button, makes it rain.
struct WeatherView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 280), spacing: 24)
    ]

    @State private var raining = false
    /// Bumped when the screen goes away, so a pending stop does nothing.
    @State private var generation = 0

    var body: some View {
        ScrollView {
            Button(action: rain) {
                Label("Shake for rain!", systemImage: "cloud.rain.fill")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color(.systemGray6)))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnWeather.allCases) { weather in
                    WeatherCard(weather: weather)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
        .overlay { RainOverlay(isActive: raining) }
        .onShake(rain)
        .onDisappear {
            generation += 1
            raining = false
            CardVoice.shared.cancel()
        }
    }

    private func rain() {
        guard !raining else { return }
        raining = true
        SoundEngine.shared.play(.rain)
        CardVoice.shared.say(Lines.itsRaining, after: nil)
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + RainOverlay.duration) {
            if gen == generation { raining = false }
        }
    }
}

#Preview {
    WeatherView()
}
