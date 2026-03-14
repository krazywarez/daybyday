//
//  WeatherView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 8 weather types as large, tappable cards in a scrollable grid.
struct WeatherView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 280), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnWeather.allCases) { weather in
                    WeatherCard(weather: weather)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    WeatherView()
}
