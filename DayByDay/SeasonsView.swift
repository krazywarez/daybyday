//
//  SeasonsView.swift
//  DayByDay
//

import SwiftUI

/// Displays all four seasons as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct SeasonsView: View {
    var body: some View {
        CardGrid(items: Season.allCases) { season in
            SeasonCard(season: season, isHighlighted: season == .current)
        }
    }
}

#Preview {
    SeasonsView()
}
