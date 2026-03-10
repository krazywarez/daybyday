//
//  SeasonsView.swift
//  DayByDay
//

import SwiftUI

/// Displays all four seasons as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct SeasonsView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(Season.allCases) { season in
                    SeasonCard(season: season, isHighlighted: season == .current)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    SeasonsView()
}
